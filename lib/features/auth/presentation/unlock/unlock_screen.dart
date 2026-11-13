import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/lock/vault_state.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/widgets/ds_logo.dart';
import '../widgets/pin_entry.dart';
import 'unlock_view_model.dart';

/// Écran de déverrouillage (docs/05-parcours-utilisateurs.md §2).
final class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

final class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  @override
  void initState() {
    super.initState();
    // Biométrie activée : la fenêtre du système s'ouvre toute seule.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vault = ref.read(vaultControllerProvider);
      if (vault is VaultLocked &&
          vault.biometricEnabled &&
          vault.reason != LockReason.biometricChanged) {
        unawaited(ref.read(unlockViewModelProvider.notifier).tryBiometrics());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(unlockViewModelProvider);
    final vm = ref.read(unlockViewModelProvider.notifier);
    final vault = ref.watch(vaultControllerProvider);
    final biometricEnabled = vault is VaultLocked && vault.biometricEnabled;
    final biometricChanged =
        vault is VaultLocked && vault.reason == LockReason.biometricChanged;
    final lockout = state.remainingLockout;

    final String title;
    final String? subtitle;
    if (lockout != null) {
      title = l10n.unlockTooManyTitle;
      subtitle = l10n.unlockTooManyBody;
    } else {
      title = l10n.unlockTitle;
      subtitle = biometricChanged ? l10n.unlockBiometricChanged : null;
    }

    final message = lockout != null
        ? l10n.unlockRetryIn(DurationFormat.short(l10n, lockout))
        : state.errorMessage(l10n);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const DsLogo(size: 56),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xs,
                  AppSpacing.xxl,
                  0,
                ),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Expanded(
              child: PinEntry(
                onSubmit: vm.submitPin,
                submitLabel: l10n.commonConfirm,
                message: message,
                messageIsError: message != null,
                enabled: lockout == null,
                busy: state.busy,
                resetToken: state.resetToken,
                onBiometric: biometricEnabled ? vm.tryBiometrics : null,
                biometricLabel: l10n.unlockBiometricButton,
                below: Center(
                  child: TextButton(
                    onPressed: () => context.push(Routes.lockRecovery),
                    child: Text(
                      lockout != null
                          ? l10n.unlockUseRecoveryKey
                          : l10n.unlockForgotPin,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
