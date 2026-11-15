import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../errors/app_exception.dart';

/// Stockage sécurisé du système (Android Keystore, Trousseau iOS).
///
/// Interface minimale pour pouvoir utiliser une version en mémoire dans les
/// tests. Les valeurs sont de courtes chaînes (JSON ou base64).
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);
}

/// Clés utilisées dans le stockage sécurisé principal.
abstract final class SecureStoreKeys {
  /// Présence d'un coffre et version de son format.
  static const vaultVersion = 'vault.version';

  /// Serrure du code (JSON, voir `VaultKeySlot`).
  static const pinSlot = 'vault.slot.pin';

  /// Indicateurs lus avant le déverrouillage (pas des secrets).
  static const biometricEnabled = 'vault.flag.biometric';
  static const screenSecure = 'vault.flag.screen_secure';

  /// Compteur d'essais du code et fin de l'attente (époque, ms).
  static const pinFailures = 'vault.pin.failures';
  static const pinLockedUntil = 'vault.pin.locked_until';

  /// Dans le stockage protégé par biométrie : clé du coffre (base64).
  static const biometricVaultKey = 'vault.slot.biometric';
}

/// Implémentation avec `flutter_secure_storage`.
final class FlutterSecureStore implements SecureStore {
  FlutterSecureStore(this._storage);

  /// Stockage principal : clé RSA du Keystore, sans biométrie.
  factory FlutterSecureStore.standard() => FlutterSecureStore(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: 'docusafe_main'),
      // Le trousseau iOS : accessible seulement téléphone déverrouillé et
      // jamais synchronisé avec iCloud. À vérifier sur iOS.
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  );

  /// Stockage dont la clé n'est libérée qu'après une biométrie **forte**
  /// (docs/04-securite.md §6). Android 9 et plus seulement.
  factory FlutterSecureStore.biometric({
    required String promptTitle,
    required String promptSubtitle,
    required String cancelLabel,
  }) => FlutterSecureStore(
    FlutterSecureStorage(
      aOptions: AndroidOptions.biometric(
        enforceBiometrics: true,
        biometricType: AndroidBiometricType.strongBiometricOnly,
        storageNamespace: 'docusafe_biometric',
        biometricPromptTitle: promptTitle,
        biometricPromptSubtitle: promptSubtitle,
        biometricPromptNegativeButton: cancelLabel,
      ),
      // iOS : élément du trousseau exigeant la biométrie actuelle, invalidé
      // si un visage ou une empreinte est ajouté. À vérifier sur iOS.
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
        accessControlFlags: [AccessControlFlag.biometryCurrentSet],
        useSecureEnclave: true,
      ),
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Exception catch (e) {
      throw StorageException('secure_store.read', cause: e);
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on Exception catch (e) {
      throw StorageException('secure_store.write', cause: e);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on Exception catch (e) {
      throw StorageException('secure_store.delete', cause: e);
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } on Exception catch (e) {
      throw StorageException('secure_store.contains', cause: e);
    }
  }
}

/// Version en mémoire, pour les tests.
final class InMemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
}
