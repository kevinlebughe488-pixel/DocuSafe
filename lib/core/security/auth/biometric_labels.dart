import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show IconData, Icons;

import '../../../app/l10n/generated/app_localizations.dart';
import 'biometric_service.dart';

/// Noms de la biométrie à l'écran.
///
/// Sur iPhone, Apple demande d'employer les noms « Face ID » et « Touch ID ».
/// Sur Android, DocuSafe parle d'« empreinte » et de « reconnaissance du
/// visage » (docs/07-design.md : mots du quotidien).
abstract final class BiometricLabels {
  static bool get _apple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Forme utilisée dans une phrase : « Utilisez *Face ID* pour ouvrir… ».
  static String inSentence(AppLocalizations l10n, BiometricKind kind) =>
      switch (kind) {
        BiometricKind.face =>
          _apple ? l10n.biometricFaceId : l10n.biometricFace,
        BiometricKind.fingerprint =>
          _apple ? l10n.biometricTouchId : l10n.biometricFingerprint,
        _ => l10n.biometricGeneric,
      };

  /// Forme utilisée comme titre : « Face ID », « Empreinte digitale ».
  static String title(AppLocalizations l10n, BiometricKind kind) =>
      switch (kind) {
        BiometricKind.face =>
          _apple ? l10n.biometricFaceId : l10n.biometricFaceTitle,
        BiometricKind.fingerprint =>
          _apple ? l10n.biometricTouchId : l10n.biometricFingerprintTitle,
        _ => l10n.biometricGenericTitle,
      };

  /// Icône correspondante.
  static IconData icon(BiometricKind kind) => switch (kind) {
    BiometricKind.face => Icons.face_rounded,
    _ => Icons.fingerprint_rounded,
  };
}
