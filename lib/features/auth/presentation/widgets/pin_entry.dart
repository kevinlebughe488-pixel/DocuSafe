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
    return LayoutBuilder(
      builder: (context, constraints) => _layout(
        context,
        theme,
        canSubmit,
        _keypadMetrics(constraints.maxHeight),
      ),
    );
  }

  /// Hauteur réservée au-dessus du clavier (points, message, bouton) :
  /// disposition ordinaire, puis disposition compacte des petits écrans.
  static const double _topHeight = 140;
  static const double _compactTopHeight = 100;

  /// Taille des touches selon la hauteur disponible : 72 points sur un écran
  /// ordinaire, moins sur un petit écran (jamais sous 44), pour que le
  /// bouton de validation ne passe jamais sous le clavier.
  ({double keySize, double rowGap, bool compact}) _keypadMetrics(
    double maxHeight,
  ) {
    if (!maxHeight.isFinite) {
      return (keySize: AppSpacing.keypadKeySize, rowGap: 7, compact: false);
    }
    final extras =
        (widget.hint != null ? 28.0 : 0.0) +
        (widget.below != null ? 48.0 : 0.0) +
        AppSpacing.sm;
    final perRow = (maxHeight - _topHeight - extras) / 4;
    if (perRow >= 58) {
      final gap = perRow >= AppSpacing.keypadKeySize + 14 ? 7.0 : 3.0;
      return (
        keySize: (perRow - 2 * gap).clamp(44.0, AppSpacing.keypadKeySize),
        rowGap: gap,
        compact: false,
      );
    }
    // Petit écran : espacements réduits au-dessus, touches resserrées.
    final compactRow = (maxHeight - _compactTopHeight - extras) / 4;
    return (
      keySize: (compactRow - 4).clamp(44.0, AppSpacing.keypadKeySize),
      rowGap: 2,
      compact: true,
    );
  }

  Widget _layout(
    BuildContext context,
    ThemeData theme,
    bool canSubmit,
    ({double keySize, double rowGap, bool compact}) keypad,
  ) {
    final compact = keypad.compact;
    return Column(
      children: [
        Expanded(
          // Défilable en dernier recours : rien ne déborde sur le clavier.
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PinDots(filled: _pin.length, hasError: widget.messageIsError),
                  SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: compact ? 28 : 40),
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
                  SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                  FilledButton.tonal(
                    style: compact
                        ? FilledButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )
                        : null,
                    onPressed: canSubmit ? _submit : null,
                    child: Text(widget.submitLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
        PinKeypad(
          keySize: keypad.keySize,
          rowGap: keypad.rowGap,
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
