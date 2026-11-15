import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/utils/error_messages.dart';
import '../../auth/presentation/widgets/pin_choice.dart';

/// Changement du code (après nouvelle authentification).
final class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

final class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _change(String pin) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(vaultControllerProvider.notifier).changePin(pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsPinChanged)),
        );
        context.pop();
      }
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePinTitle)),
      body: SafeArea(
        child: PinChoice(
          title: l10n.changePinTitle,
          body: l10n.changePinBody,
          busy: _busy,
          externalError: _error,
          onChosen: _change,
        ),
      ),
    );
  }
}
