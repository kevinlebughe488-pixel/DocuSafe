import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/security/auth/pin_policy.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../core/widgets/step_header.dart';
import 'pin_entry.dart';

/// Choix d'un nouveau code en deux temps : saisie puis confirmation.
///
/// Réutilisé par la création du coffre, la récupération et le changement de
/// code. [onChosen] reçoit le code validé et confirmé.
final class PinChoice extends StatefulWidget {
  const PinChoice({
    super.key,
    required this.onChosen,
    required this.title,
    required this.body,
    this.step,
    this.totalSteps,
    this.busy = false,
    this.externalError,
  });

  final ValueChanged<String> onChosen;
  final String title;
  final String body;

  /// Si fournis, un [StepHeader] est affiché (création du coffre).
  final int? step;
  final int? totalSteps;
  final bool busy;

  /// Message d'erreur venant de l'extérieur (échec de l'enregistrement).
  final String? externalError;

  @override
  State<PinChoice> createState() => _PinChoiceState();
}

final class _PinChoiceState extends State<PinChoice> {
  String? _first;
  String? _error;
  int _reset = 0;

  void _submit(String pin) {
    final l10n = AppLocalizations.of(context);
    if (_first == null) {
      try {
        PinPolicy.validate(pin);
      } on ValidationException catch (e) {
        setState(() {
          _error = ErrorMessages.of(l10n, e);
          _reset++;
        });
        return;
      }
      setState(() {
        _first = pin;
        _error = null;
        _reset++;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = l10n.setupPinMismatch;
        _reset++;
      });
      return;
    }
    setState(() => _error = null);
    widget.onChosen(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final confirming = _first != null;
    final title = confirming ? l10n.setupPinConfirmTitle : widget.title;
    final body = confirming ? l10n.setupPinConfirmBody : widget.body;
    final error = widget.externalError ?? _error;
    return Column(
      children: [
        if (widget.step != null && widget.totalSteps != null)
          StepHeader(
            step: widget.step!,
            total: widget.totalSteps!,
            title: title,
            body: body,
          )
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: PinEntry(
            key: ValueKey(confirming),
            onSubmit: _submit,
            submitLabel: l10n.commonContinue,
            message: error,
            messageIsError: error != null,
            hint: confirming ? null : l10n.setupPinHint,
            busy: widget.busy,
            resetToken: _reset,
          ),
        ),
      ],
    );
  }
}
