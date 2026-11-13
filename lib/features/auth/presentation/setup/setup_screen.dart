import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/security/auth/biometric_service.dart';
import '../../../../core/widgets/bottom_actions.dart';
import '../../../../core/widgets/illustration_circle.dart';
import '../../../../core/widgets/step_header.dart';
import '../widgets/pin_choice.dart';
import '../widgets/recovery_key_view.dart';
import 'setup_view_model.dart';

/// Création du coffre en trois étapes : code, clé de récupération,
/// biométrie facultative (docs/05-parcours-utilisateurs.md §1).
final class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupViewModelProvider);
    final vm = ref.read(setupViewModelProvider.notifier);
    final l10n = AppLocalizations.of(context);

    ref.listen(setupViewModelProvider, (previous, next) {
      if (next.stage == SetupStage.done) {
        context.go(Routes.home);
      }
    });

    final Widget body = switch (state.stage) {
      SetupStage.pin || SetupStage.preparing => PinChoice(
        key: const ValueKey('pin'),
        step: 1,
        totalSteps: 3,
        title: l10n.setupPinTitle,
        body: l10n.setupPinBody,
        busy: state.stage == SetupStage.preparing,
        externalError: state.errorMessage(l10n),
        onChosen: vm.choosePin,
      ),
      SetupStage.recoveryKey || SetupStage.committing => _RecoveryStep(
        key: const ValueKey('recovery'),
        state: state,
        vm: vm,
      ),
      SetupStage.biometric || SetupStage.enablingBiometric => _BiometricStep(
        key: const ValueKey('biometric'),
        state: state,
        vm: vm,
      ),
      SetupStage.done => const SizedBox.shrink(),
    };

    final canGoBack =
        state.stage == SetupStage.pin || state.stage == SetupStage.recoveryKey;

    return PopScope(
      canPop: canGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && state.stage == SetupStage.recoveryKey) {
          vm.discard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: canGoBack
              ? BackButton(
                  onPressed: () {
                    if (state.stage == SetupStage.recoveryKey) {
                      vm.discard();
                    } else {
                      context.go(Routes.onboarding);
                    }
                  },
                )
              : const SizedBox.shrink(),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: body,
          ),
        ),
      ),
    );
  }
}

final class _RecoveryStep extends StatelessWidget {
  const _RecoveryStep({super.key, required this.state, required this.vm});

  final SetupState state;
  final SetupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final error = state.errorMessage(l10n);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                StepHeader(
                  step: 2,
                  total: 3,
                  title: l10n.setupRecoveryTitle,
                  body: l10n.setupRecoveryBody,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: RecoveryKeyView(recoveryKey: state.pending!.recoveryKey),
                ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        CheckboxListTile.adaptive(
          value: state.recoveryKeyConfirmed,
          onChanged: state.stage == SetupStage.committing
              ? null
              : (v) => vm.setRecoveryConfirmed(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(l10n.setupRecoveryChecked),
        ),
        BottomActions(
          children: [
            state.stage == SetupStage.committing
                ? const Center(child: CircularProgressIndicator.adaptive())
                : LargeFilledButton(
                    label: l10n.commonContinue,
                    onPressed: state.recoveryKeyConfirmed ? vm.commit : null,
                  ),
          ],
        ),
      ],
    );
  }
}

final class _BiometricStep extends StatelessWidget {
  const _BiometricStep({super.key, required this.state, required this.vm});

  final SetupState state;
  final SetupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final face = state.biometricKind == BiometricKind.face;
    final busy = state.stage == SetupStage.enablingBiometric;
    final error = state.errorMessage(l10n);
    return Column(
      children: [
        StepHeader(
          step: 3,
          total: 3,
          title: l10n.setupBiometricTitle,
          body: face ? l10n.setupBiometricBodyFace : l10n.setupBiometricBody,
        ),
        Expanded(
          child: Center(
            child: IllustrationCircle(
              icon: face ? Icons.face_rounded : Icons.fingerprint_rounded,
              security: true,
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        BottomActions(
          children: [
            LargeFilledButton(
              label: face
                  ? l10n.setupBiometricEnableFace
                  : l10n.setupBiometricEnable,
              icon: face ? Icons.face_rounded : Icons.fingerprint_rounded,
              onPressed: busy ? null : vm.enableBiometrics,
            ),
            TextButton(
              onPressed: busy ? null : vm.skipBiometrics,
              child: Text(l10n.commonLater),
            ),
          ],
        ),
      ],
    );
  }
}
