import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/keys/recovery_key.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/bottom_actions.dart';
import '../../../../core/widgets/info_banner.dart';
import '../widgets/pin_choice.dart';

/// « Code oublié » : saisie de la clé de récupération, puis nouveau code
/// (docs/05-parcours-utilisateurs.md §2).
final class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

final class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  bool _unlocked = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final key = RecoveryKey.parse(_controller.text);
      await ref
          .read(vaultControllerProvider.notifier)
          .unlockWithRecoveryKey(key);
      setState(() => _unlocked = true);
    } on AppException catch (e) {
      setState(() => _error = ErrorMessages.of(l10n, e));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _setNewPin(String pin) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(vaultControllerProvider.notifier).changePin(pin);
      // Le coffre est ouvert : le routeur quitte cet écran de lui-même.
    } on AppException catch (e) {
      setState(() {
        _busy = false;
        _error = ErrorMessages.of(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = RecoveryKey.countValidChars(_controller.text);
    final complete = count == RecoveryKey.charLength;

    return Scaffold(
      appBar: AppBar(
        title: Text(_unlocked ? l10n.recoveryNewPinTitle : l10n.recoveryTitle),
        automaticallyImplyLeading: !_unlocked,
      ),
      body: SafeArea(
        child: _unlocked
            ? PinChoice(
                title: l10n.recoveryNewPinTitle,
                body: l10n.recoveryNewPinBody,
                busy: _busy,
                externalError: _error,
                onChosen: _setNewPin,
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.screenMargin),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.recoveryBody,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextField(
                            controller: _controller,
                            autofocus: true,
                            enabled: !_busy,
                            textCapitalization: TextCapitalization.characters,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: TextInputType.visiblePassword,
                            style: const TextStyle(fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              labelText: l10n.recoveryFieldLabel,
                              helperText: l10n.recoveryCount(
                                count,
                                RecoveryKey.charLength,
                              ),
                              errorText: _error,
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: complete && !_busy
                                ? (_) => _verify()
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          InfoBanner.text(
                            kind: InfoBannerKind.info,
                            text: l10n.recoveryInfo,
                          ),
                        ],
                      ),
                    ),
                  ),
                  BottomActions(
                    children: [
                      LargeFilledButton(
                        label: l10n.recoveryVerify,
                        onPressed: complete && !_busy ? _verify : null,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
