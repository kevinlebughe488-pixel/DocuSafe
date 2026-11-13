import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/pin_dots.dart';
import '../../../../core/widgets/pin_keypad.dart';

/// Saisie d'un code : points, message, bouton de validation et clavier.
///
/// Le code a une longueur variable (6 à 12 chiffres) : l'utilisateur valide
/// avec le bouton dès que six chiffres sont saisis.
final class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.onSubmit,
    required this.submitLabel,
    this.message,
    this.messageIsError = false,
    this.hint,
    this.enabled = true,
    this.busy = false,
    this.onBiometric,
    this.biometricIcon = Icons.fingerprint_rounded,
    this.biometricLabel,
    this.resetToken = 0,
    this.below,
  });

  final ValueChanged<String> onSubmit;
  final String submitLabel;
  final String? message;
  final bool messageIsError;
  final String? hint;
  final bool enabled;
  final bool busy;
  final VoidCallback? onBiometric;
  final IconData biometricIcon;
  final String? biometricLabel;

  /// Changer cette valeur efface la saisie.
  final int resetToken;

  /// Contenu facultatif sous le clavier (« Code oublié ? »).
  final Widget? below;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

final class _PinEntryState extends State<PinEntry> {
  String _pin = '';

  @override
  void didUpdateWidget(covariant PinEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _pin = '';
    }
  }

  void _digit(String d) {
    if (_pin.length >= AppConfig.pinMaxLength) {
      return;
    }
    setState(() => _pin += d);
  }

  void _backspace() {
    if (_pin.isEmpty) {
      return;
    }
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    final pin = _pin;
    setState(() => _pin = '');
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit =
        widget.enabled && !widget.busy && _pin.length >= AppConfig.pinMinLength;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PinDots(filled: _pin.length, hasError: widget.messageIsError),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 40,
                  child: widget.busy
                      ? const Center(
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                          ),
                          child: Text(
                            widget.message ?? '',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: widget.messageIsError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonal(
                  onPressed: canSubmit ? _submit : null,
                  child: Text(widget.submitLabel),
                ),
              ],
            ),
          ),
        ),
        PinKeypad(
          onDigit: _digit,
          onBackspace: _backspace,
          onBiometric: widget.onBiometric,
          biometricIcon: widget.biometricIcon,
          biometricLabel: widget.biometricLabel,
          enabled: widget.enabled && !widget.busy,
        ),
        if (widget.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              widget.hint!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (widget.below != null) widget.below!,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}
