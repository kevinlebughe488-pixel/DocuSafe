import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/pin_dots.dart';
import '../../../../core/widgets/pin_keypad.dart';

/// Saisie d'un code : points, message et clavier.
///
/// Avec [length] (6 chiffres, D5 révisée le 15/11/2026), le code est validé
/// tout seul dès le dernier chiffre : pas de bouton. Sans [length] (coffre
/// créé avant cette date, code de 6 à 12 chiffres), un bouton [submitLabel]
/// valide le code dès que six chiffres sont saisis.
final class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.onSubmit,
    this.length = AppConfig.pinLength,
    this.submitLabel,
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

  /// Longueur du code, ou `null` pour un ancien coffre (bouton de validation).
  final int? length;

  /// Libellé du bouton, utilisé seulement sans [length].
  final String? submitLabel;
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

  /// Validation automatique, juste après l'affichage du dernier point.
  Timer? _autoSubmit;

  @override
  void didUpdateWidget(covariant PinEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetToken != widget.resetToken) {
      _autoSubmit?.cancel();
      _pin = '';
    }
  }

  @override
  void dispose() {
    _autoSubmit?.cancel();
    super.dispose();
  }

  void _digit(String d) {
    final length = widget.length;
    if (_pin.length >= (length ?? AppConfig.legacyPinMaxLength)) {
      return;
    }
    setState(() => _pin += d);
    if (length != null && _pin.length == length) {
      _autoSubmit?.cancel();
      _autoSubmit = Timer(const Duration(milliseconds: 150), _submit);
    }
  }

  void _backspace() {
    if (_pin.isEmpty) {
      return;
    }
    _autoSubmit?.cancel();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    _autoSubmit?.cancel();
    final length = widget.length;
    if (!mounted || (length != null && _pin.length != length)) {
      return;
    }
    final pin = _pin;
    setState(() => _pin = '');
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit =
        widget.enabled && !widget.busy && _pin.length >= AppConfig.pinLength;
    // Très grande police (accessibilité, §6.3) : tout l'écran défile plutôt
    // que de déborder ; les touches gardent leur taille normale.
    final largeText = MediaQuery.textScalerOf(context).scale(10) > 13;
    if (largeText) {
      return SingleChildScrollView(
        child: _layout(context, theme, canSubmit, (
          keySize: AppSpacing.keypadKeySize,
          rowGap: 7,
          compact: false,
        ), scrollable: true),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => _layout(
        context,
        theme,
        canSubmit,
        _keypadMetrics(constraints.maxHeight),
      ),
    );
  }

  /// Hauteur réservée au-dessus du clavier (points, message, bouton s'il
  /// existe) : disposition ordinaire, puis compacte des petits écrans.
  double get _topHeight => widget.length == null ? 140 : 96;
  double get _compactTopHeight => widget.length == null ? 100 : 68;

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
    ({double keySize, double rowGap, bool compact}) keypad, {
    bool scrollable = false,
  }) {
    final compact = keypad.compact;
    final top = _top(theme, canSubmit, compact);
    return Column(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (scrollable)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: top,
          )
        else
          Expanded(
            // Défilable en dernier recours : rien ne déborde sur le clavier.
            child: Center(child: SingleChildScrollView(child: top)),
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

  /// Points, message et bouton de validation.
  Widget _top(ThemeData theme, bool canSubmit, bool compact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PinDots(
          filled: _pin.length,
          minDots: widget.length ?? AppConfig.pinLength,
          hasError: widget.messageIsError,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 28 : 40),
          child: widget.busy
              ? const Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
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
        // Ancien coffre seulement : code de longueur variable.
        if (widget.length == null) ...[
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          FilledButton.tonal(
            style: compact
                ? FilledButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                : null,
            onPressed: canSubmit ? _submit : null,
            child: Text(widget.submitLabel ?? ''),
          ),
        ],
      ],
    );
  }
}
