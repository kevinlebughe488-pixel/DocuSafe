import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/error_messages.dart';
import '../widgets/pin_entry.dart';

/// Nouvelle authentification avant une opération sensible
/// (docs/04-securite.md §11) : biométrie si elle est activée, sinon code.
/// Une authentification de moins de 30 secondes n'est pas redemandée.
///
/// Retourne `true` si l'utilisateur a été reconnu.
Future<bool> requestReauth(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(vaultControllerProvider.notifier);
  if (controller.recentlyAuthenticated) {
    return true;
  }
  final l10n = AppLocalizations.of(context);
  if (await controller.service.isBiometricEnabled()) {
    controller.beginExternalOperation();
    try {
      final ok = await ref
          .read(biometricServiceProvider)
          .authenticate(reason: l10n.reauthBiometricReason);
      if (ok) {
        controller.markAuthenticated();
        return true;
      }
    } on AuthException {
      // Biométrie indisponible : on passe au code.
    } finally {
      controller.endExternalOperation();
    }
  }
  if (!context.mounted) {
    return false;
  }
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _ReauthSheet(),
  );
  return result ?? false;
}

final class _ReauthSheet extends ConsumerStatefulWidget {
  const _ReauthSheet();

  @override
  ConsumerState<_ReauthSheet> createState() => _ReauthSheetState();
}

final class _ReauthSheetState extends ConsumerState<_ReauthSheet> {
  bool _busy = false;
  String? _error;
  int _reset = 0;

  Future<void> _submit(String pin) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(vaultControllerProvider.notifier).verifyPin(pin);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on AppException catch (e) {
      setState(() {
        _busy = false;
        _error = ErrorMessages.of(l10n, e);
        _reset++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pinLength = ref.watch(pinLengthProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Text(l10n.reauthTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.reauthBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PinEntry(
              onSubmit: _submit,
              length: pinLength.hasValue ? pinLength.value : AppConfig.pinLength,
              submitLabel: l10n.commonConfirm,
              message: _error,
              messageIsError: _error != null,
              busy: _busy,
              resetToken: _reset,
            ),
          ),
        ],
      ),
    );
  }
}
