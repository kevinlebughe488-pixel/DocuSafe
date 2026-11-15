/// Erreurs typées de l'application (docs/02-architecture.md §9).
///
/// Les couches basses lèvent une de ces erreurs ; les ViewModels les
/// transforment en état d'écran. Aucune erreur ne transporte de donnée
/// sensible (titre, chemin, contenu, clé) : seulement un code et, parfois,
/// une valeur technique neutre (durée d'attente, nombre d'essais).
sealed class AppException implements Exception {
  const AppException(this.code);

  /// Code court, stable, utilisable dans le journal technique.
  final String code;

  @override
  String toString() => '$runtimeType($code)';
}

/// Problème de stockage : espace insuffisant, fichier illisible, dossier absent.
final class StorageException extends AppException {
  const StorageException(super.code, {this.cause});

  final Object? cause;

  @override
  String toString() => 'StorageException($code, cause: ${cause.runtimeType})';
}

/// Chiffrement ou déchiffrement impossible, ou intégrité non vérifiée.
final class CryptoException extends AppException {
  const CryptoException(super.code);

  /// Le fichier a été modifié, tronqué ou n'a pas été chiffré avec cette clé.
  static const integrity = CryptoException('crypto.integrity');

  /// Format de fichier chiffré inconnu ou en-tête invalide.
  static const badFormat = CryptoException('crypto.bad_format');

  /// Version du format plus récente que celle connue de l'application.
  static const unsupportedVersion = CryptoException('crypto.unsupported_version');
}

/// Authentification refusée ou impossible.
final class AuthException extends AppException {
  const AuthException(super.code, {this.remainingAttempts, this.lockedFor});

  /// Code faux. [remainingAttempts] : essais libres restants avant l'attente.
  const AuthException.wrongPin({required int this.remainingAttempts})
    : lockedFor = null,
      super('auth.wrong_pin');

  /// Trop d'essais : il faut patienter [lockedFor].
  const AuthException.lockedOut({required Duration this.lockedFor})
    : remainingAttempts = null,
      super('auth.locked_out');

  /// Clé de récupération mal formée ou incorrecte.
  const AuthException.recoveryKeyInvalid()
    : remainingAttempts = null,
      lockedFor = null,
      super('auth.recovery_key_invalid');

  /// La biométrie n'est pas disponible ou n'est plus valable (empreinte ajoutée).
  const AuthException.biometricUnavailable()
    : remainingAttempts = null,
      lockedFor = null,
      super('auth.biometric_unavailable');

  /// L'utilisateur a annulé ou échoué la fenêtre biométrique.
  const AuthException.biometricFailed()
    : remainingAttempts = null,
      lockedFor = null,
      super('auth.biometric_failed');

  /// Aucun coffre n'existe sur cet appareil.
  const AuthException.noVault()
    : remainingAttempts = null,
      lockedFor = null,
      super('auth.no_vault');

  /// Le stockage sécurisé du téléphone a perdu la serrure du code.
  const AuthException.slotMissing()
    : remainingAttempts = null,
      lockedFor = null,
      super('auth.slot_missing');

  final int? remainingAttempts;
  final Duration? lockedFor;
}

/// Donnée saisie refusée (code trop simple, nom vide…).
final class ValidationException extends AppException {
  const ValidationException(super.code);

  /// Code trop court, trop long, ou contenant autre chose que des chiffres.
  static const pinFormat = ValidationException('validation.pin_format');

  /// Code trop simple : suite ou répétition évidente.
  static const pinTooSimple = ValidationException('validation.pin_too_simple');

  /// Les deux saisies du code ne correspondent pas.
  static const pinMismatch = ValidationException('validation.pin_mismatch');
}

/// Le coffre est verrouillé alors qu'une opération exigeait qu'il soit ouvert.
final class VaultLockedException extends AppException {
  const VaultLockedException() : super('vault.locked');
}

/// Le scanner n'a pas pu s'ouvrir. [cameraDenied] : l'appareil photo est
/// refusé à DocSafe (iPhone ; aucune autorisation n'est utile sur Android).
final class ScannerException extends AppException {
  const ScannerException({this.cameraDenied = false})
    : super(cameraDenied ? 'scanner.camera_denied' : 'scanner.failed');

  final bool cameraDenied;
}

/// L'utilisateur a annulé l'opération en cours.
final class CancelledException extends AppException {
  const CancelledException() : super('cancelled');
}
