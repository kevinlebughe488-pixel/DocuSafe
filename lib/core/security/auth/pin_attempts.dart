import '../../config/app_config.dart';
import '../../errors/app_exception.dart';
import '../keys/secure_store.dart';

/// Compteur d'essais du code et attentes croissantes (docs/04-securite.md §5).
///
/// 5 essais libres, puis 30 s, 1 min, 5 min, 15 min, 1 h (et 1 h ensuite).
/// Le compteur est conservé dans le stockage sécurisé : il survit à la
/// fermeture de l'application.
final class PinAttempts {
  PinAttempts(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SecureStore _store;
  final DateTime Function() _clock;

  /// Nombre d'échecs consécutifs enregistrés.
  Future<int> failures() async {
    final raw = await _store.read(SecureStoreKeys.pinFailures);
    return raw == null ? 0 : int.tryParse(raw) ?? 0;
  }

  /// Durée d'attente restante, ou `null` si un essai est permis.
  Future<Duration?> remainingLockout() async {
    final raw = await _store.read(SecureStoreKeys.pinLockedUntil);
    if (raw == null) {
      return null;
    }
    final until = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(raw) ?? 0,
      isUtc: true,
    );
    final now = _clock().toUtc();
    if (!until.isAfter(now)) {
      return null;
    }
    return until.difference(now);
  }

  /// Lève [AuthException.lockedOut] si une attente est en cours.
  Future<void> ensureAllowed() async {
    final remaining = await remainingLockout();
    if (remaining != null) {
      throw AuthException.lockedOut(lockedFor: remaining);
    }
  }

  /// Enregistre un échec et retourne l'erreur à présenter à l'utilisateur.
  Future<AuthException> recordFailure() async {
    final count = await failures() + 1;
    await _store.write(SecureStoreKeys.pinFailures, '$count');
    final lockout = lockoutFor(count);
    if (lockout == null) {
      return AuthException.wrongPin(
        remainingAttempts: AppConfig.pinFreeAttempts - count,
      );
    }
    final until = _clock().toUtc().add(lockout);
    await _store.write(
      SecureStoreKeys.pinLockedUntil,
      '${until.millisecondsSinceEpoch}',
    );
    return AuthException.lockedOut(lockedFor: lockout);
  }

  /// Remet le compteur à zéro après un succès.
  Future<void> reset() async {
    await _store.delete(SecureStoreKeys.pinFailures);
    await _store.delete(SecureStoreKeys.pinLockedUntil);
  }

  /// Attente imposée après [failureCount] échecs consécutifs, ou `null`
  /// tant que des essais libres restent. Le 5e échec déclenche la première
  /// attente (30 s), le 6e la deuxième (1 min), et ainsi de suite.
  static Duration? lockoutFor(int failureCount) {
    final index = failureCount - AppConfig.pinFreeAttempts;
    if (index < 0) {
      return null;
    }
    const steps = AppConfig.pinLockoutSteps;
    return steps[index < steps.length ? index : steps.length - 1];
  }
}
