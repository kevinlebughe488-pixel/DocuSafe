import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'security/auth/biometric_service.dart';
import 'security/auth/pin_attempts.dart';
import 'security/crypto/crypto_engine.dart';
import 'security/crypto/dart_crypto_engine.dart';
import 'security/crypto/file_cipher.dart';
import 'security/keys/secure_store.dart';
import 'security/lock/vault_controller.dart';
import 'security/lock/vault_state.dart';
import 'security/screen/screen_security.dart';
import 'security/vault_service.dart';
import 'storage/vault_paths.dart';

/// Providers des services partagés. Dans les tests, ils sont remplacés par
/// des versions simulées via `ProviderScope(overrides: …)`.

final cryptoEngineProvider = Provider<CryptoEngine>(
  (ref) => const DartCryptoEngine(),
);

final fileCipherProvider = Provider<FileCipher>(
  (ref) => FileCipher(ref.watch(cryptoEngineProvider)),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => FlutterSecureStore.standard(),
);

/// Stockage protégé par biométrie forte. `null` sur les plateformes où il
/// n'existe pas ; sur Android 7 et 8 il n'est jamais lu car la biométrie n'est
/// pas proposée (voir [BiometricService]).
final biometricStoreProvider = Provider<SecureStore?>((ref) {
  if (kIsWeb) {
    return null;
  }
  return FlutterSecureStore.biometric(
    promptTitle: 'Déverrouiller DocuSafe',
    promptSubtitle: 'Utilisez votre empreinte ou votre visage',
    cancelLabel: 'Utiliser mon code',
  );
});

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => LocalAuthBiometricService(),
);

final screenSecurityProvider = Provider<ScreenSecurity>(
  (ref) => const ChannelScreenSecurity(),
);

/// Horloge, remplaçable dans les tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Dossiers du coffre, résolus une fois au démarrage (voir `main.dart`).
final vaultPathsProvider = Provider<VaultPaths>(
  (ref) => throw UnimplementedError('vaultPathsProvider doit être remplacé'),
);

final vaultServiceProvider = Provider<VaultService>(
  (ref) => VaultService(
    crypto: ref.watch(cryptoEngineProvider),
    store: ref.watch(secureStoreProvider),
    biometricStore: ref.watch(biometricStoreProvider),
    paths: ref.watch(vaultPathsProvider),
    attempts: PinAttempts(ref.watch(secureStoreProvider)),
  ),
);

final vaultControllerProvider = NotifierProvider<VaultController, VaultState>(
  VaultController.new,
);

/// Base de données de la session en cours. Lève [VaultLockedException] si le
/// coffre est verrouillé : aucun écran protégé ne doit l'observer dans cet état.
final databaseProvider = Provider<AppDatabase>(
  (ref) => ref.watch(vaultControllerProvider.notifier).requireSession().database,
);
