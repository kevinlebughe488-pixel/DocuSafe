import '../../app/l10n/generated/app_localizations.dart';
import '../errors/app_exception.dart';
import 'duration_format.dart';

/// Transforme une erreur typée en message français clair (jamais technique).
abstract final class ErrorMessages {
  static String of(AppLocalizations l10n, Object error) => switch (error) {
    AuthException(code: 'auth.wrong_pin', :final remainingAttempts) =>
      l10n.unlockWrongPin(remainingAttempts ?? 0),
    AuthException(code: 'auth.locked_out', :final lockedFor) =>
      l10n.unlockRetryIn(
        DurationFormat.short(l10n, lockedFor ?? Duration.zero),
      ),
    AuthException(code: 'auth.recovery_key_invalid') => l10n.recoveryInvalid,
    AuthException(code: 'auth.biometric_unavailable') =>
      l10n.errorBiometricUnavailable,
    AuthException(code: 'auth.biometric_failed') =>
      l10n.errorBiometricUnavailable,
    AuthException(code: 'auth.slot_missing') => l10n.unlockSlotMissing,
    ValidationException(code: 'validation.pin_too_simple') =>
      l10n.setupPinTooSimple,
    ValidationException(code: 'validation.pin_format') => l10n.setupPinTooShort,
    ValidationException(code: 'validation.pin_mismatch') =>
      l10n.setupPinMismatch,
    CryptoException() => l10n.errorIntegrity,
    StorageException(code: 'storage.insufficient') => l10n.storageInsufficient,
    StorageException() => l10n.errorStorage,
    VaultLockedException() => l10n.errorVaultLocked,
    ScannerException(cameraDenied: true) => l10n.errorScannerCamera,
    ScannerException() => l10n.errorScanner,
    _ => l10n.errorUnexpected,
  };
}
