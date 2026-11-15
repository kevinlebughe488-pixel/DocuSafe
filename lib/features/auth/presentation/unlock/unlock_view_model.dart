import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/lock/vault_state.dart';
import '../../../../core/utils/error_messages.dart';

final class UnlockState {
  const UnlockState({
    this.busy = false,
    this.error,
    this.lockedUntil,
    this.now,
    this.biometricTried = false,
    this.resetToken = 0,
  });

  final bool busy;
  final Object? error;

  /// Fin de l'attente après trop d'essais, ou `null`.
  final DateTime? lockedUntil;
  final DateTime? now;
  final bool biometricTried;
  final int resetToken;

  Duration? get remainingLockout {
    final until = lockedUntil;
    final current = now;
    if (until == null || current == null || !until.isAfter(current)) {
      return null;
    }
    return until.difference(current);
  }

  bool get isLockedOut => remainingLockout != null;

  String? errorMessage(AppLocalizations l10n) =>
      error == null ? null : ErrorMessages.of(l10n, error!);

  UnlockState copyWith({
    bool? busy,
    Object? error,
    bool clearError = false,
    DateTime? lockedUntil,
    bool clearLockout = false,
    DateTime? now,
    bool? biometricTried,
    int? resetToken,
  }) => UnlockState(
    busy: busy ?? this.busy,
    error: clearError ? null : (error ?? this.error),
    lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
    now: now ?? this.now,
    biometricTried: biometricTried ?? this.biometricTried,
    resetToken: resetToken ?? this.resetToken,
  );
}

/// ViewModel de l'écran de déverrouillage.
base class UnlockViewModel extends Notifier<UnlockState> {
  Timer? _ticker;

  @override
  UnlockState build() {
    ref.onDispose(() => _ticker?.cancel());
    unawaited(_loadLockout());
    return const UnlockState();
  }

  Future<void> _loadLockout() async {
    final remaining = await ref
        .read(vaultServiceProvider)
        .attempts
        .remainingLockout();
    if (remaining != null) {
      _startLockout(remaining);
    }
  }

  void _startLockout(Duration remaining) {
    final now = DateTime.now();
    state = state.copyWith(lockedUntil: now.add(remaining), now: now);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = DateTime.now();
      state = state.copyWith(now: current);
      if (!state.isLockedOut) {
        _ticker?.cancel();
        state = state.copyWith(clearLockout: true, clearError: true);
      }
    });
  }

  Future<void> submitPin(String pin) async {
    if (state.busy) {
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(vaultControllerProvider.notifier).unlockWithPin(pin);
      state = state.copyWith(busy: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        busy: false,
        error: e,
        resetToken: state.resetToken + 1,
      );
      if (e.lockedFor != null) {
        _startLockout(e.lockedFor!);
      }
    } on AppException catch (e) {
      state = state.copyWith(busy: false, error: e);
    }
  }

  /// Ouvre la fenêtre biométrique du système.
  Future<void> tryBiometrics() async {
    if (state.busy) {
      return;
    }
    final vault = ref.read(vaultControllerProvider);
    if (vault is! VaultLocked || !vault.biometricEnabled) {
      return;
    }
    state = state.copyWith(busy: true, clearError: true, biometricTried: true);
    try {
      await ref.read(vaultControllerProvider.notifier).unlockWithBiometrics();
      state = state.copyWith(busy: false);
    } on AuthException catch (e) {
      // Annulation ou échec : le clavier reste disponible, sans message
      // alarmant si l'utilisateur a simplement fermé la fenêtre.
      state = state.copyWith(
        busy: false,
        error: e.code == 'auth.biometric_failed' ? null : e,
      );
    } on AppException catch (e) {
      state = state.copyWith(busy: false, error: e);
    }
  }
}

final unlockViewModelProvider = NotifierProvider<UnlockViewModel, UnlockState>(
  UnlockViewModel.new,
);
