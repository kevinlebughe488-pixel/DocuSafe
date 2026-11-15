import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../errors/app_exception.dart';
import '../storage/vault_paths.dart';
import '../utils/app_log.dart';
import '../utils/bytes.dart';
import 'auth/pin_attempts.dart';
import 'auth/pin_policy.dart';
import 'crypto/argon2_params.dart';
import 'crypto/crypto_engine.dart';
import 'crypto/key_derivation.dart';
import 'keys/recovery_key.dart';
import 'keys/secure_store.dart';
import 'keys/vault_key_slot.dart';
import 'lock/vault_session.dart';

/// Coffre préparé mais pas encore enregistré : rien n'est écrit sur le
/// téléphone tant que [VaultService.commitSetup] n'est pas appelé
/// (docs/05-parcours-utilisateurs.md §1 : « l'utilisateur quitte avant la
/// fin : rien n'est créé »).
final class PendingVaultSetup {
  PendingVaultSetup._({
    required this.recoveryKey,
    required this._vaultKey,
    required this.pinSlot,
    required this.recoverySlot,
  });

  final RecoveryKey recoveryKey;
  final Uint8List _vaultKey;
  final VaultKeySlot pinSlot;
  final VaultKeySlot recoverySlot;

  /// Abandon : efface la clé en mémoire.
  void discard() => Bytes.wipe(_vaultKey);
}

/// Opérations sur le coffre : création, déverrouillage, serrures, effacement.
///
/// Correspond aux cas d'utilisation `SetupVault`, `UnlockVault`, `LockVault`,
/// `ChangePin`, `EnableBiometrics`, `RegenerateRecoveryKey` et `WipeVault`
/// de docs/02-architecture.md §1. La base est ouverte à l'intérieur de la
/// session retournée ; la fermer est le rôle de [VaultSession.close].
final class VaultService {
  VaultService({
    required CryptoEngine crypto,
    required this._store,
    required this._biometricStore,
    required this._paths,
    required this.attempts,
    this.argon2Params = Argon2Params.standard,
    AppDatabase Function(File file, Uint8List key)? openDatabase,
  }) : _crypto = crypto,
       _keys = KeyDerivation(crypto),
       _openDatabase = openDatabase ?? AppDatabase.openEncrypted;

  final CryptoEngine _crypto;
  final SecureStore _store;

  /// Stockage protégé par biométrie, ou `null` si le téléphone ne le permet
  /// pas.
  final SecureStore? _biometricStore;
  final VaultPaths _paths;
  final KeyDerivation _keys;
  final PinAttempts attempts;
  final Argon2Params argon2Params;
  final AppDatabase Function(File file, Uint8List key) _openDatabase;

  static const String _vaultFormatVersion = '1';

  // ---------------------------------------------------------------------------
  // État
  // ---------------------------------------------------------------------------

  /// Un coffre existe-t-il sur cet appareil ?
  Future<bool> hasVault() async =>
      await _store.read(SecureStoreKeys.vaultVersion) != null;

  Future<bool> isBiometricEnabled() async =>
      await _store.read(SecureStoreKeys.biometricEnabled) == '1';

  /// Captures d'écran bloquées (vrai par défaut).
  /// Supprime les fichiers temporaires en clair (appelé au verrouillage).
  Future<void> purgeTemporaryFiles() async {
    try {
      await _paths.purgeSecureTemp();
    } on FileSystemException catch (e, s) {
      AppLog.error('vault.temp_purge', e, s);
    }
  }

  Future<bool> isScreenSecure() async =>
      await _store.read(SecureStoreKeys.screenSecure) != '0';

  Future<void> setScreenSecure(bool secure) =>
      _store.write(SecureStoreKeys.screenSecure, secure ? '1' : '0');

  // ---------------------------------------------------------------------------
  // Création (SetupVault)
  // ---------------------------------------------------------------------------

  /// Prépare un nouveau coffre à partir du code : tire la clé du coffre et la
  /// clé de récupération, calcule les deux serrures. N'écrit rien.
  Future<PendingVaultSetup> prepareSetup(String pin) async {
    PinPolicy.validate(pin);
    final vaultKey = _crypto.randomBytes(CryptoEngine.keyLength);
    final recoveryKey = RecoveryKey.generate();
    AppLog.event('vault.setup.pin_slot.start');
    final pinSlot = await _wrapWithPin(vaultKey, pin);
    AppLog.event('vault.setup.recovery_slot.start');
    final recoverySlot = await _wrapWithRecoveryKey(vaultKey, recoveryKey);
    AppLog.event('vault.setup.prepared');
    return PendingVaultSetup._(
      recoveryKey: recoveryKey,
      vaultKey: vaultKey,
      pinSlot: pinSlot,
      recoverySlot: recoverySlot,
    );
  }

  /// Enregistre le coffre préparé et l'ouvre.
  Future<VaultSession> commitSetup(PendingVaultSetup pending) async {
    if (await hasVault()) {
      throw const StorageException('vault.already_exists');
    }
    await _paths.ensureCreated();
    await _paths.recoverySlotFile.writeAsString(
      pending.recoverySlot.encode(),
      flush: true,
    );
    AppLog.event('vault.commit.recovery_slot_written');
    await _store.write(SecureStoreKeys.pinSlot, pending.pinSlot.encode());
    AppLog.event('vault.commit.pin_slot_stored');
    await _store.write(SecureStoreKeys.biometricEnabled, '0');
    await _store.write(SecureStoreKeys.screenSecure, '1');
    await attempts.reset();
    // Écrit en dernier : sa présence signifie « coffre complet ».
    await _store.write(SecureStoreKeys.vaultVersion, _vaultFormatVersion);
    AppLog.event('vault.created');
    return _openSession(pending._vaultKey);
  }

  // ---------------------------------------------------------------------------
  // Déverrouillage (UnlockVault)
  // ---------------------------------------------------------------------------

  Future<VaultSession> unlockWithPin(String pin) async {
    final vaultKey = await _unwrapWithPin(pin);
    AppLog.event('vault.unlocked.pin');
    return _openSession(vaultKey);
  }

  Future<VaultSession> unlockWithRecoveryKey(RecoveryKey recoveryKey) async {
    final vaultKey = await _unwrapWithRecoveryKey(recoveryKey);
    await attempts.reset();
    AppLog.event('vault.unlocked.recovery');
    return _openSession(vaultKey);
  }

  /// Lit la clé du coffre dans le stockage protégé par biométrie. Le système
  /// affiche lui-même la fenêtre d'authentification.
  Future<VaultSession> unlockWithBiometrics() async {
    final bioStore = _biometricStore;
    if (bioStore == null || !await isBiometricEnabled()) {
      throw const AuthException.biometricUnavailable();
    }
    String? raw;
    try {
      raw = await bioStore.read(SecureStoreKeys.biometricVaultKey);
    } on StorageException catch (e, s) {
      // Clé détruite (nouvelle empreinte) ou fenêtre annulée.
      AppLog.error('vault.biometric.read', e, s);
      throw const AuthException.biometricFailed();
    }
    if (raw == null) {
      await _store.write(SecureStoreKeys.biometricEnabled, '0');
      throw const AuthException.biometricUnavailable();
    }
    final vaultKey = base64Decode(raw);
    await attempts.reset();
    AppLog.event('vault.unlocked.biometric');
    return _openSession(vaultKey);
  }

  /// Vérifie le code sans ouvrir la base (nouvelle authentification §11).
  Future<void> verifyPin(String pin) async {
    final key = await _unwrapWithPin(pin);
    Bytes.wipe(key);
  }

  // ---------------------------------------------------------------------------
  // Serrures
  // ---------------------------------------------------------------------------

  /// Refait la serrure du code. Les documents ne sont pas rechiffrés.
  Future<void> changePin(VaultSession session, String newPin) async {
    PinPolicy.validate(newPin);
    final slot = await _wrapWithPin(session.vaultKey, newPin);
    await _store.write(SecureStoreKeys.pinSlot, slot.encode());
    await attempts.reset();
    AppLog.event('vault.pin_changed');
  }

  /// Active la biométrie : copie de la clé dans le stockage protégé.
  Future<void> enableBiometrics(VaultSession session) async {
    final bioStore = _biometricStore;
    if (bioStore == null) {
      throw const AuthException.biometricUnavailable();
    }
    await bioStore.write(
      SecureStoreKeys.biometricVaultKey,
      base64Encode(session.vaultKey),
    );
    await _store.write(SecureStoreKeys.biometricEnabled, '1');
    await session.database.settingsDao.setBiometricEnabled(true);
    AppLog.event('vault.biometric_enabled');
  }

  Future<void> disableBiometrics(VaultSession? session) async {
    try {
      await _biometricStore?.delete(SecureStoreKeys.biometricVaultKey);
    } on StorageException catch (e, s) {
      AppLog.error('vault.biometric.delete', e, s);
    }
    await _store.write(SecureStoreKeys.biometricEnabled, '0');
    await session?.database.settingsDao.setBiometricEnabled(false);
    AppLog.event('vault.biometric_disabled');
  }

  /// Nouvelle clé de récupération ; l'ancienne cesse de fonctionner.
  Future<RecoveryKey> regenerateRecoveryKey(VaultSession session) async {
    final recoveryKey = RecoveryKey.generate();
    final slot = await _wrapWithRecoveryKey(session.vaultKey, recoveryKey);
    final tmp = File('${_paths.recoverySlotFile.path}.part');
    await tmp.writeAsString(slot.encode(), flush: true);
    await tmp.rename(_paths.recoverySlotFile.path);
    AppLog.event('vault.recovery_regenerated');
    return recoveryKey;
  }

  // ---------------------------------------------------------------------------
  // Effacement (WipeVault)
  // ---------------------------------------------------------------------------

  /// Détruit les clés puis supprime tous les fichiers du coffre.
  Future<void> wipe(VaultSession? session) async {
    await session?.close();
    // Les clés d'abord : sans elles, le reste est inexploitable.
    await _store.delete(SecureStoreKeys.vaultVersion);
    await _store.delete(SecureStoreKeys.pinSlot);
    await disableBiometrics(null);
    await attempts.reset();
    await _store.delete(SecureStoreKeys.biometricEnabled);
    await _store.delete(SecureStoreKeys.screenSecure);
    await _paths.deleteEverything();
    AppLog.event('vault.wiped');
  }

  // ---------------------------------------------------------------------------
  // Restauration d'une sauvegarde (choix D13)
  // ---------------------------------------------------------------------------

  /// Remplace le coffre par la sauvegarde décompressée dans
  /// [VaultPaths.restoreDir], ouverte avec [vaultKey] (tirée de sa serrure de
  /// récupération), et la protège par le nouveau code [pin].
  ///
  /// Le coffre actuel n'est effacé qu'une fois la nouvelle serrure prête. La
  /// biométrie est désactivée : elle se réactive dans les réglages.
  Future<VaultSession> restore({
    required Uint8List vaultKey,
    required String pin,
    VaultSession? current,
  }) async {
    PinPolicy.validate(pin);
    final source = _paths.restoreDir;
    if (!await File('${source.path}/${AppConfig.databaseFileName}').exists()) {
      throw const StorageException('backup.not_unpacked');
    }
    final pinSlot = await _wrapWithPin(vaultKey, pin);
    await wipe(current);
    await source.rename(_paths.vaultDir.path);
    await _store.write(SecureStoreKeys.pinSlot, pinSlot.encode());
    await _store.write(SecureStoreKeys.biometricEnabled, '0');
    await _store.write(SecureStoreKeys.screenSecure, '1');
    await attempts.reset();
    await _store.write(SecureStoreKeys.vaultVersion, _vaultFormatVersion);
    final session = await _openSession(vaultKey);
    await session.database.settingsDao.setBiometricEnabled(false);
    AppLog.event('vault.restored');
    return session;
  }

  // ---------------------------------------------------------------------------
  // Détails
  // ---------------------------------------------------------------------------

  Future<VaultSession> _openSession(Uint8List vaultKey) async {
    await _paths.ensureCreated();
    await _paths.purgeSecureTemp();
    await _paths.purgePartialFiles();
    AppLog.event('vault.session.opening');
    final dbKey = await _keys.databaseKey(vaultKey);
    try {
      final database = _openDatabase(_paths.databaseFile, dbKey);
      final session = VaultSession(
        vaultKey: vaultKey,
        filesRootKey: await _keys.filesRootKey(vaultKey),
        thumbnailsRootKey: await _keys.thumbnailsRootKey(vaultKey),
        database: database,
      );
      try {
        await database.ensureOpened();
        AppLog.event('vault.session.database_opened');
        await _removeOrphanFiles(database);
      } on Object {
        await session.close();
        rethrow;
      }
      return session;
    } finally {
      Bytes.wipe(dbKey);
    }
  }

  /// Contrôle de cohérence, avant que la session ne soit utilisée : aucun
  /// enregistrement ne peut donc être en cours. Un échec n'empêche jamais
  /// d'ouvrir le coffre.
  Future<void> _removeOrphanFiles(AppDatabase database) async {
    try {
      final references = await database.documentsDao.allFileReferences();
      final removed = _paths.removeOrphans({
        for (final (id, path) in references) ...[
          path,
          VaultPaths.thumbnailRelativePath(id),
        ],
      });
      if (removed > 0) {
        AppLog.event('vault.orphans_removed');
      }
    } on Object catch (e, s) {
      AppLog.error('vault.consistency', e, s);
    }
  }

  Future<VaultKeySlot> _wrapWithPin(Uint8List vaultKey, String pin) async {
    final salt = _crypto.randomBytes(16);
    final nonce = _crypto.randomBytes(CryptoEngine.gcmNonceLength);
    final pinKey = await _crypto.argon2id(
      password: Uint8List.fromList(utf8.encode(pin)),
      salt: salt,
      params: argon2Params,
    );
    AppLog.event('vault.pin_slot.key_derived');
    try {
      final wrapped = await _crypto.aesGcmEncrypt(
        key: pinKey,
        nonce: nonce,
        plaintext: vaultKey,
        aad: VaultKeySlot.aadPin,
      );
      AppLog.event('vault.pin_slot.wrapped');
      return VaultKeySlot(
        kdf: VaultKeySlot.kdfArgon2id,
        argon2: argon2Params,
        salt: salt,
        nonce: nonce,
        wrappedKey: wrapped,
      );
    } finally {
      Bytes.wipe(pinKey);
    }
  }

  Future<Uint8List> _unwrapWithPin(String pin) async {
    if (!await hasVault()) {
      throw const AuthException.noVault();
    }
    await attempts.ensureAllowed();
    final raw = await _store.read(SecureStoreKeys.pinSlot);
    if (raw == null) {
      throw const AuthException.slotMissing();
    }
    final slot = VaultKeySlot.decode(raw);
    final params = slot.argon2;
    if (slot.kdf != VaultKeySlot.kdfArgon2id || params == null) {
      throw CryptoException.badFormat;
    }
    final pinKey = await _crypto.argon2id(
      password: Uint8List.fromList(utf8.encode(pin)),
      salt: slot.salt,
      params: params,
    );
    try {
      final vaultKey = await _crypto.aesGcmDecrypt(
        key: pinKey,
        nonce: slot.nonce,
        ciphertextWithTag: slot.wrappedKey,
        aad: VaultKeySlot.aadPin,
      );
      await attempts.reset();
      return vaultKey;
    } on CryptoException {
      throw await attempts.recordFailure();
    } finally {
      Bytes.wipe(pinKey);
    }
  }

  Future<VaultKeySlot> _wrapWithRecoveryKey(
    Uint8List vaultKey,
    RecoveryKey recoveryKey,
  ) async {
    final salt = _crypto.randomBytes(16);
    final nonce = _crypto.randomBytes(CryptoEngine.gcmNonceLength);
    final slotKey = await _keys.recoverySlotKey(recoveryKey.bytes, salt);
    try {
      final wrapped = await _crypto.aesGcmEncrypt(
        key: slotKey,
        nonce: nonce,
        plaintext: vaultKey,
        aad: VaultKeySlot.aadRecovery,
      );
      return VaultKeySlot(
        kdf: VaultKeySlot.kdfHkdf,
        salt: salt,
        nonce: nonce,
        wrappedKey: wrapped,
      );
    } finally {
      Bytes.wipe(slotKey);
    }
  }

  Future<Uint8List> _unwrapWithRecoveryKey(RecoveryKey recoveryKey) async {
    if (!await hasVault()) {
      throw const AuthException.noVault();
    }
    final file = _paths.recoverySlotFile;
    if (!await file.exists()) {
      throw const AuthException.slotMissing();
    }
    return unwrapRecoverySlot(await file.readAsString(), recoveryKey);
  }

  /// Ouvre une serrure de récupération (celle du coffre ou d'une sauvegarde).
  /// Lève [AuthException.recoveryKeyInvalid] si la clé ne correspond pas.
  Future<Uint8List> unwrapRecoverySlot(
    String encodedSlot,
    RecoveryKey recoveryKey,
  ) async {
    final VaultKeySlot slot;
    try {
      slot = VaultKeySlot.decode(encodedSlot);
    } on Object {
      throw CryptoException.badFormat;
    }
    if (slot.kdf != VaultKeySlot.kdfHkdf) {
      throw CryptoException.badFormat;
    }
    final slotKey = await _keys.recoverySlotKey(recoveryKey.bytes, slot.salt);
    try {
      return await _crypto.aesGcmDecrypt(
        key: slotKey,
        nonce: slot.nonce,
        ciphertextWithTag: slot.wrappedKey,
        aad: VaultKeySlot.aadRecovery,
      );
    } on CryptoException {
      throw const AuthException.recoveryKeyInvalid();
    } finally {
      Bytes.wipe(slotKey);
    }
  }
}
