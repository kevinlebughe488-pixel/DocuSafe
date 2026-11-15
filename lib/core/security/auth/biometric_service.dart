import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../errors/app_exception.dart';
import '../../utils/app_log.dart';

/// Ce que le téléphone propose comme biométrie.
enum BiometricKind { none, fingerprint, face, other }

/// Détection et confirmation biométriques (docs/04-securite.md §6).
///
/// Ce service ne libère **aucune clé** : la clé biométrique est protégée par
/// le stockage sécurisé lui-même. Il sert à savoir si la biométrie est
/// disponible et à confirmer une opération sensible (§11).
abstract interface class BiometricService {
  /// Biométrie forte disponible **et** enregistrée sur ce téléphone.
  Future<BiometricKind> availableKind();

  /// Ouvre la fenêtre du système. Retourne vrai si l'utilisateur est reconnu.
  Future<bool> authenticate({required String reason});
}

/// Implémentation avec `local_auth`.
final class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService({LocalAuthentication? auth, this._androidSdkInt})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;
  final int? _androidSdkInt;

  @override
  Future<BiometricKind> availableKind() async {
    try {
      // Android 7 et 8 : pas de protection matérielle de la clé par la
      // biométrie dans le paquet de stockage sécurisé → non proposée (D7).
      if (Platform.isAndroid && !await _androidSupportsBiometricKeys()) {
        return BiometricKind.none;
      }
      if (!await _auth.canCheckBiometrics) {
        return BiometricKind.none;
      }
      final types = await _auth.getAvailableBiometrics();
      // Seule la biométrie « forte » (classe 3) libère la clé.
      if (!types.contains(BiometricType.strong)) {
        return BiometricKind.none;
      }
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricKind.fingerprint;
      }
      if (types.contains(BiometricType.face)) {
        return BiometricKind.face;
      }
      return BiometricKind.other;
    } on PlatformException catch (e, s) {
      AppLog.error('biometric.availability', e, s);
      return BiometricKind.none;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on PlatformException catch (e, s) {
      AppLog.error('biometric.authenticate', e, s);
      throw const AuthException.biometricUnavailable();
    }
  }

  Future<bool> _androidSupportsBiometricKeys() async {
    final sdk = _androidSdkInt ?? await _readAndroidSdkInt();
    return sdk >= 28;
  }

  /// Version d'Android, lue par le canal `docusafe/platform`.
  static Future<int> _readAndroidSdkInt() async {
    const channel = MethodChannel('docusafe/platform');
    try {
      return await channel.invokeMethod<int>('androidSdkInt') ?? 0;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }
}

/// Aucune biométrie : utilisé dans les tests et sur les plateformes sans
/// prise en charge.
final class NoBiometricService implements BiometricService {
  const NoBiometricService();

  @override
  Future<BiometricKind> availableKind() async => BiometricKind.none;

  @override
  Future<bool> authenticate({required String reason}) async => false;
}
