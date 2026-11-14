import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/security/auth/biometric_labels.dart';
import '../../../core/security/auth/biometric_service.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../auth/presentation/reauth/reauth_sheet.dart';
import 'security_settings_view_model.dart';

/// Réglages de sécurité (écran 17). Chaque changement sensible demande une
/// nouvelle authentification (docs/04-securite.md §11).
final class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(securitySettingsProvider);
    final vm = ref.read(securitySettingsProvider.notifier);

    ref.listen(securitySettingsProvider, (previous, next) {
      final msg = next.message;
      if (msg != null && msg != previous?.message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.resolve(l10n))),
        );
        vm.clearMessage();
      }
    });

    final kind = state.biometricKind;
    final biometricAvailable = kind != BiometricKind.none;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSecurityTitle)),
      body: ListView(
        children: [
          SettingsTile(
            icon: Icons.password_rounded,
            title: l10n.settingsChangePin,
            onTap: () async {
              if (await requestReauth(context, ref) && context.mounted) {
                await context.push(Routes.settingsChangePin);
              }
            },
          ),
          SettingsTile.toggle(
            icon: BiometricLabels.icon(kind),
            title: BiometricLabels.title(l10n, kind),
            subtitle: biometricAvailable
                ? l10n.settingsBiometricSubtitle(
                    BiometricLabels.inSentence(l10n, kind),
                  )
                : l10n.settingsBiometricUnavailable,
            value: state.biometricEnabled,
            onChanged: biometricAvailable && !state.busy
                ? (value) async {
                    if (await requestReauth(context, ref)) {
                      await vm.setBiometrics(value);
                    }
                  }
                : null,
          ),
          SettingsTile(
            icon: Icons.key_rounded,
            title: l10n.settingsRecoveryKey,
            subtitle: state.recoveryKeyConfirmed
                ? l10n.settingsRecoveryKeySubtitle
                : l10n.settingsRecoveryKeyTodo,
            onTap: () async {
              if (await requestReauth(context, ref) && context.mounted) {
                await context.push(
                  state.recoveryKeyConfirmed
                      ? Routes.settingsRecoveryKey
                      : Routes.recoveryKeyFirstTime,
                );
              }
            },
          ),
          SettingsGroupLabel(l10n.settingsLockSection),
          SettingsTile(
            icon: Icons.lock_clock_rounded,
            title: l10n.settingsAutoLock,
            subtitle: l10n.settingsAutoLockSubtitle(
              DurationFormat.short(l10n, state.autoLock),
            ),
            onTap: () => _chooseAutoLock(context, ref, state.autoLock),
          ),
          SettingsTile.toggle(
            icon: Icons.screenshot_rounded,
            title: l10n.settingsScreenshots,
            subtitle: l10n.settingsScreenshotsSubtitle,
            value: !state.screenSecure,
            onChanged: state.busy
                ? null
                : (allow) async {
                    // Autoriser les captures est l'opération sensible.
                    if (!allow || await requestReauth(context, ref)) {
                      await vm.setScreenshotsAllowed(allow);
                    }
                  },
          ),
          SettingsTile(
            icon: Icons.lock_outline_rounded,
            title: l10n.settingsLockNow,
            trailing: const SizedBox.shrink(),
            onTap: () => ref
                .read(vaultControllerProvider.notifier)
                .lock(currentLocation: Routes.settingsSecurity),
          ),
          SettingsGroupLabel(l10n.settingsDangerSection),
          SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: l10n.settingsWipe,
            subtitle: l10n.settingsWipeSubtitle,
            danger: true,
            trailing: const SizedBox.shrink(),
            onTap: () async {
              if (await requestReauth(context, ref) && context.mounted) {
                await _confirmWipe(context, ref);
              }
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _chooseAutoLock(
    BuildContext context,
    WidgetRef ref,
    Duration current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<Duration>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.settingsAutoLockChoice,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            RadioGroup<Duration>(
              groupValue: current,
              onChanged: (v) => Navigator.of(ctx).pop(v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final d in AppConfig.autoLockChoices)
                    RadioListTile.adaptive(
                      value: d,
                      title: Text(DurationFormat.short(l10n, d)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (choice != null) {
      await ref.read(securitySettingsProvider.notifier).setAutoLock(choice);
    }
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _WipeDialog(),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(vaultControllerProvider.notifier).wipe();
      // Le routeur renvoie à l'onboarding dès que l'état devient « absent ».
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMessages.of(l10n, e))),
        );
      }
    }
  }
}

/// Confirmation écrite de l'effacement (docs/04-securite.md §18).
final class _WipeDialog extends StatefulWidget {
  const _WipeDialog();

  @override
  State<_WipeDialog> createState() => _WipeDialogState();
}

final class _WipeDialogState extends State<_WipeDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ok = _controller.text.trim().toUpperCase() == l10n.settingsWipeConfirmWord;
    return AlertDialog.adaptive(
      title: Text(l10n.settingsWipeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.settingsWipeBody),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.settingsWipeFieldLabel),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: ok ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.settingsWipeAction),
        ),
      ],
    );
  }
}
