import 'dart:io';

import 'package:docusafe/core/config/app_config.dart';
import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/security/auth/pin_attempts.dart';
import 'package:docusafe/core/security/crypto/argon2_params.dart';
import 'package:docusafe/core/security/crypto/dart_crypto_engine.dart';
import 'package:docusafe/core/security/keys/recovery_key.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/core/storage/vault_paths.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests des clés et de l'authentification (docs/04-securite.md §20).
void main() {
  late Directory root;
  late InMemorySecureStore store;
  late InMemorySecureStore bioStore;
  late VaultPaths paths;
  late DateTime now;
  late VaultService service;

  const pin = '204915';
  const otherPin = '731906';

  setUp(() async {
    root = await Directory.systemTemp.createTemp('vault_test');
    store = InMemorySecureStore();
    bioStore = InMemorySecureStore();
    paths = VaultPaths.under(root);
    now = DateTime.utc(2026, 11, 13, 12);
    service = VaultService(
      crypto: const DartCryptoEngine(),
      store: store,
      biometricStore: bioStore,
      paths: paths,
      attempts: PinAttempts(store, clock: () => now),
      argon2Params: Argon2Params.testOnly,
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<RecoveryKey> createVault() async {
    final pending = await service.prepareSetup(pin);
    final session = await service.commitSetup(pending);
    await session.close();
    return pending.recoveryKey;
  }

  test('préparer sans valider : rien n\'est écrit', () async {
    final pending = await service.prepareSetup(pin);
    expect(await service.hasVault(), isFalse);
    expect(paths.vaultDir.existsSync(), isFalse);
    pending.discard();
  });

  test('créer puis déverrouiller avec le code', () async {
    await createVault();
    expect(await service.hasVault(), isTrue);
    expect(paths.databaseFile.existsSync(), isTrue);
    expect(paths.recoverySlotFile.existsSync(), isTrue);

    final session = await service.unlockWithPin(pin);
    final categories = await session.database.categoriesDao.getAll();
    expect(categories.length, 7);
    expect(categories.last.name, 'Autres');
    expect(categories.last.isSystem, isTrue);
    await session.close();
    expect(session.isClosed, isTrue);
    expect(() => session.vaultKey, throwsStateError);
  });

  test('la base sur le disque est chiffrée', () async {
    await createVault();
    final bytes = paths.databaseFile.readAsBytesSync();
    expect(String.fromCharCodes(bytes.take(15)), isNot('SQLite format 3'));
    expect(String.fromCharCodes(bytes).contains('Identité'), isFalse);
    expect(String.fromCharCodes(bytes).contains('categories'), isFalse);
  });

  test('mauvais code : refus, compteur, attentes croissantes', () async {
    await createVault();
    for (var i = 1; i <= AppConfig.pinFreeAttempts; i++) {
      final error = await _expectAuthError(service.unlockWithPin(otherPin));
      if (i < AppConfig.pinFreeAttempts) {
        expect(error.code, 'auth.wrong_pin');
        expect(error.remainingAttempts, AppConfig.pinFreeAttempts - i);
      } else {
        expect(error.code, 'auth.locked_out');
        expect(error.lockedFor, const Duration(seconds: 30));
      }
    }
    // Pendant l'attente, même le bon code est refusé.
    var error = await _expectAuthError(service.unlockWithPin(pin));
    expect(error.code, 'auth.locked_out');
    expect(error.lockedFor, lessThanOrEqualTo(const Duration(seconds: 30)));

    // Après l'attente : nouvel échec → 1 minute.
    now = now.add(const Duration(seconds: 31));
    error = await _expectAuthError(service.unlockWithPin(otherPin));
    expect(error.lockedFor, const Duration(minutes: 1));

    // Le compteur a survécu : il est dans le stockage sécurisé.
    expect(await service.attempts.failures(), 6);

    // Bon code après l'attente : succès et remise à zéro.
    now = now.add(const Duration(minutes: 2));
    final session = await service.unlockWithPin(pin);
    expect(await service.attempts.failures(), 0);
    await session.close();
  });

  test('clé de récupération : déverrouille, puis nouveau code', () async {
    final recoveryKey = await createVault();
    final typed = recoveryKey.display.toLowerCase();
    final session = await service.unlockWithRecoveryKey(RecoveryKey.parse(typed));
    await service.changePin(session, otherPin);
    await session.close();

    await _expectAuthError(service.unlockWithPin(pin));
    final again = await service.unlockWithPin(otherPin);
    await again.close();
  });

  test('clé de récupération fausse refusée', () async {
    await createVault();
    final wrong = RecoveryKey.generate();
    final error = await _expectAuthError(
      service.unlockWithRecoveryKey(wrong),
    );
    expect(error.code, 'auth.recovery_key_invalid');
  });

  test('nouvelle clé de récupération : l\'ancienne ne marche plus', () async {
    final oldKey = await createVault();
    final session = await service.unlockWithPin(pin);
    final newKey = await service.regenerateRecoveryKey(session);
    await session.close();

    await _expectAuthError(service.unlockWithRecoveryKey(oldKey));
    final s2 = await service.unlockWithRecoveryKey(newKey);
    await s2.close();
  });

  test('biométrie : activer, déverrouiller, désactiver', () async {
    await createVault();
    expect(await service.isBiometricEnabled(), isFalse);
    await _expectAuthError(service.unlockWithBiometrics());

    final session = await service.unlockWithPin(pin);
    await service.enableBiometrics(session);
    await session.close();
    expect(await service.isBiometricEnabled(), isTrue);
    expect(bioStore.values.containsKey(SecureStoreKeys.biometricVaultKey), isTrue);

    final s2 = await service.unlockWithBiometrics();
    expect((await s2.database.settingsDao.get()).biometricEnabled, isTrue);
    await service.disableBiometrics(s2);
    await s2.close();
    expect(bioStore.values, isEmpty);
    expect(await service.isBiometricEnabled(), isFalse);
  });

  test('biométrie perdue (clé détruite par le système)', () async {
    await createVault();
    final session = await service.unlockWithPin(pin);
    await service.enableBiometrics(session);
    await session.close();
    bioStore.values.clear();
    final error = await _expectAuthError(service.unlockWithBiometrics());
    expect(error.code, 'auth.biometric_unavailable');
    expect(await service.isBiometricEnabled(), isFalse);
  });

  test('vérification du code sans ouvrir la base', () async {
    await createVault();
    await service.verifyPin(pin);
    await _expectAuthError(service.verifyPin(otherPin));
  });

  test('changer le code ne rechiffre pas la base', () async {
    await createVault();
    final before = paths.databaseFile.lastModifiedSync();
    final session = await service.unlockWithPin(pin);
    await service.changePin(session, otherPin);
    await session.close();
    // Le fichier de la base est intact : seule la serrure a changé.
    expect(paths.databaseFile.lastModifiedSync(), before);
  });

  test('effacer le coffre', () async {
    await createVault();
    final session = await service.unlockWithPin(pin);
    await service.enableBiometrics(session);
    await service.wipe(session);
    expect(await service.hasVault(), isFalse);
    expect(store.values, isEmpty);
    expect(bioStore.values, isEmpty);
    expect(paths.vaultDir.existsSync(), isFalse);
    final error = await _expectAuthError(service.unlockWithPin(pin));
    expect(error.code, 'auth.no_vault');
  });

  test('code trop simple refusé à la création', () async {
    await expectLater(
      service.prepareSetup('123456'),
      throwsA(same(ValidationException.pinTooSimple)),
    );
  });

  test('attentes : 30 s, 1, 5, 15, 60 min puis 60 min', () {
    expect(PinAttempts.lockoutFor(4), isNull);
    expect(PinAttempts.lockoutFor(5), const Duration(seconds: 30));
    expect(PinAttempts.lockoutFor(6), const Duration(minutes: 1));
    expect(PinAttempts.lockoutFor(7), const Duration(minutes: 5));
    expect(PinAttempts.lockoutFor(8), const Duration(minutes: 15));
    expect(PinAttempts.lockoutFor(9), const Duration(hours: 1));
    expect(PinAttempts.lockoutFor(25), const Duration(hours: 1));
  });
}

Future<AuthException> _expectAuthError(Future<Object?> future) async {
  try {
    await future;
  } on AuthException catch (e) {
    return e;
  }
  fail('AuthException attendue');
}
