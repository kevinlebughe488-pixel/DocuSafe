import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/security/auth/biometric_labels.dart';
import '../../../../core/widgets/bottom_actions.dart';
import '../../../../core/widgets/illustration_circle.dart';
import '../../../../core/widgets/step_header.dart';
import '../widgets/pin_choice.dart';
import 'setup_view_model.dart';

/// Création du coffre en deux étapes : code, puis biométrie facultative
/// (docs/05-parcours-utilisateurs.md §1, D6 révisée). La clé de
/// récupération est créée en silence et proposée ensuite sur l'accueil.
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
      SetupStage.pin || SetupStage.creating => PinChoice(
        key: const ValueKey('pin'),
        step: 1,
        totalSteps: state.totalSteps,
        title: l10n.setupPinTitle,
        body: l10n.setupPinBody,
        busy: state.stage == SetupStage.creating,
        externalError: state.errorMessage(l10n),
        onChosen: vm.choosePin,
      ),
      SetupStage.biometric || SetupStage.enablingBiometric => _BiometricStep(
        key: const ValueKey('biometric'),
        state: state,
        vm: vm,
      ),
      SetupStage.done => const SizedBox.shrink(),
    };

    // Retour possible seulement avant la création du coffre.
    final canGoBack = state.stage == SetupStage.pin;

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        appBar: AppBar(
          leading: canGoBack
              ? BackButton(onPressed: () => context.go(Routes.onboarding))
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

final class _BiometricStep extends StatelessWidget {
  const _BiometricStep({super.key, required this.state, required this.vm});

  final SetupState state;
  final SetupViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = state.biometricKind;
    final method = BiometricLabels.inSentence(l10n, kind);
    final busy = state.stage == SetupStage.enablingBiometric;
    final error = state.errorMessage(l10n);
    return Column(
      children: [
        StepHeader(
          step: 2,
          total: 2,
          title: l10n.setupBiometricTitle,
          body: l10n.setupBiometricBody(method),
        ),
        Expanded(
          child: Center(
            child: IllustrationCircle(
              icon: BiometricLabels.icon(kind),
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
              label: l10n.setupBiometricEnable(method),
              icon: BiometricLabels.icon(kind),
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
