import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/auth/biometric_service.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/error_messages.dart';

/// Étapes de la création du coffre (D6 révisée le 14/11/2026) : le code,
/// puis la biométrie si le téléphone la propose. La clé de récupération est
/// créée en silence ; un rappel sur l'accueil invite à la noter.
enum SetupStage { pin, creating, biometric, enablingBiometric, done }

final class SetupState {
  const SetupState({
    this.stage = SetupStage.pin,
    this.biometricKind = BiometricKind.none,
    this.error,
  });

  final SetupStage stage;
  final BiometricKind biometricKind;
  final Object? error;

  /// Nombre d'étapes affichées : 2 si la biométrie est disponible, sinon 1.
  int get totalSteps => biometricKind == BiometricKind.none ? 1 : 2;

  String? errorMessage(AppLocalizations l10n) =>
      error == null ? null : ErrorMessages.of(l10n, error!);

  SetupState copyWith({
    SetupStage? stage,
    BiometricKind? biometricKind,
    Object? error,
    bool clearError = true,
  }) => SetupState(
    stage: stage ?? this.stage,
    biometricKind: biometricKind ?? this.biometricKind,
    error: clearError ? error : (error ?? this.error),
  );
}

/// ViewModel de la création du coffre.
base class SetupViewModel extends Notifier<SetupState> {
  @override
  SetupState build() {
    unawaited(_detectBiometrics());
    return const SetupState();
  }

  Future<void> _detectBiometrics() async {
    final kind = await ref.read(biometricServiceProvider).availableKind();
    if (ref.mounted) {
      state = state.copyWith(biometricKind: kind, clearError: false);
    }
  }

  /// Code choisi et confirmé : le coffre est créé et ouvert aussitôt.
  Future<void> choosePin(String pin) async {
    state = state.copyWith(stage: SetupStage.creating);
    AppLog.event('setup.choose_pin');
    try {
      final controller = ref.read(vaultControllerProvider.notifier);
      final pending = await controller.prepareSetup(pin);
      AppLog.event('setup.prepared');
      await controller.commitSetup(pending);
      AppLog.event('setup.committed');
    } on AppException catch (e, s) {
      AppLog.error('setup.create', e, s);
      state = state.copyWith(stage: SetupStage.pin, error: e);
      return;
    } on Object catch (e, s) {
      // Erreur imprévue : jamais de roue qui tourne sans fin.
      AppLog.error('setup.create.unexpected', e, s);
      state = state.copyWith(stage: SetupStage.pin, error: e);
      return;
    }
    // Le coffre existe : la suite ne doit plus pouvoir bloquer l'entrée.
    var kind = BiometricKind.none;
    try {
      kind = await ref
          .read(biometricServiceProvider)
          .availableKind()
          .timeout(const Duration(seconds: 5));
    } on Object catch (e, s) {
      AppLog.error('setup.biometric_check', e, s);
    }
    AppLog.event('setup.done.${kind.name}');
    state = state.copyWith(
      stage: kind == BiometricKind.none
          ? SetupStage.done
          : SetupStage.biometric,
      biometricKind: kind,
    );
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
