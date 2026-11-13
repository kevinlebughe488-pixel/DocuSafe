import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/auth/biometric_service.dart';
import '../../../../core/security/vault_service.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/error_messages.dart';

enum SetupStage {
  pin,
  preparing,
  recoveryKey,
  committing,
  biometric,
  enablingBiometric,
  done,
}

final class SetupState {
  const SetupState({
    this.stage = SetupStage.pin,
    this.pending,
    this.recoveryKeyConfirmed = false,
    this.biometricKind = BiometricKind.none,
    this.error,
  });

  final SetupStage stage;
  final PendingVaultSetup? pending;
  final bool recoveryKeyConfirmed;
  final BiometricKind biometricKind;
  final Object? error;

  String? errorMessage(AppLocalizations l10n) =>
      error == null ? null : ErrorMessages.of(l10n, error!);

  SetupState copyWith({
    SetupStage? stage,
    PendingVaultSetup? pending,
    bool clearPending = false,
    bool? recoveryKeyConfirmed,
    BiometricKind? biometricKind,
    Object? error,
    bool clearError = true,
  }) => SetupState(
    stage: stage ?? this.stage,
    pending: clearPending ? null : (pending ?? this.pending),
    recoveryKeyConfirmed: recoveryKeyConfirmed ?? this.recoveryKeyConfirmed,
    biometricKind: biometricKind ?? this.biometricKind,
    error: clearError ? error : (error ?? this.error),
  );
}

/// ViewModel de la création du coffre.
base class SetupViewModel extends Notifier<SetupState> {
  /// Copie du coffre en préparation, pour l'effacer si l'écran disparaît.
  PendingVaultSetup? _pending;

  @override
  SetupState build() {
    ref.onDispose(() => _pending?.discard());
    return const SetupState();
  }

  Future<void> choosePin(String pin) async {
    state = state.copyWith(stage: SetupStage.preparing);
    try {
      final pending = await ref
          .read(vaultControllerProvider.notifier)
          .prepareSetup(pin);
      _pending = pending;
      state = state.copyWith(stage: SetupStage.recoveryKey, pending: pending);
    } on AppException catch (e) {
      state = state.copyWith(stage: SetupStage.pin, error: e);
    }
  }

  void setRecoveryConfirmed(bool value) =>
      state = state.copyWith(recoveryKeyConfirmed: value);

  /// Retour en arrière depuis la clé : rien n'a été écrit, on recommence.
  void discard() {
    _pending?.discard();
    _pending = null;
    state = const SetupState();
  }

  Future<void> commit() async {
    final pending = state.pending;
    if (pending == null || !state.recoveryKeyConfirmed) {
      return;
    }
    state = state.copyWith(stage: SetupStage.committing);
    try {
      await ref.read(vaultControllerProvider.notifier).commitSetup(pending);
      _pending = null;
      final kind = await ref.read(biometricServiceProvider).availableKind();
      if (kind == BiometricKind.none) {
        state = state.copyWith(stage: SetupStage.done, clearPending: true);
      } else {
        state = state.copyWith(
          stage: SetupStage.biometric,
          biometricKind: kind,
          clearPending: true,
        );
      }
    } on AppException catch (e, s) {
      AppLog.error('setup.commit', e, s);
      state = state.copyWith(stage: SetupStage.recoveryKey, error: e);
    }
  }

  Future<void> enableBiometrics() async {
    state = state.copyWith(stage: SetupStage.enablingBiometric);
    try {
      await ref.read(vaultControllerProvider.notifier).enableBiometrics();
      state = state.copyWith(stage: SetupStage.done);
    } on AppException catch (e, s) {
      AppLog.error('setup.biometric', e, s);
      state = state.copyWith(
        stage: SetupStage.biometric,
        error: const AuthException.biometricFailed(),
      );
    }
  }

  void skipBiometrics() => state = state.copyWith(stage: SetupStage.done);
}

final setupViewModelProvider = NotifierProvider<SetupViewModel, SetupState>(
  SetupViewModel.new,
);
