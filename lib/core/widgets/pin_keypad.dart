import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_spacing.dart';

/// Clavier numérique dessiné par l'application (docs/04-securite.md §5 :
/// pas le clavier du système). Touches de 72 points, zone tactile large.
final class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.biometricIcon = Icons.fingerprint_rounded,
    this.biometricLabel,
    this.enabled = true,
    this.keySize = AppSpacing.keypadKeySize,
    this.rowGap = 7,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// Touche biométrique en bas à gauche, si fournie.
  final VoidCallback? onBiometric;
  final IconData biometricIcon;
  final String? biometricLabel;
  final bool enabled;

  /// Diamètre d'une touche et demi-espace entre deux rangées. Réduits par
  /// [PinEntry] sur les petits écrans, sans descendre sous 44 points.
  final double keySize;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.38,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final row in rows)
              _KeyRow(
                gap: rowGap,
                children: [for (final d in row) _DigitKey(d, onDigit, keySize)],
              ),
            _KeyRow(
              gap: rowGap,
              children: [
                if (onBiometric != null)
                  _IconKey(
                    icon: biometricIcon,
                    label: biometricLabel ?? 'Biométrie',
                    onTap: onBiometric!,
                    size: keySize,
                  )
                else
                  SizedBox.square(dimension: keySize),
                _DigitKey('0', onDigit, keySize),
                _IconKey(
                  icon: Icons.backspace_outlined,
                  label: 'Effacer le dernier chiffre',
                  onTap: onBackspace,
                  size: keySize,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children, required this.gap});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: gap),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 28),
          children[i],
        ],
      ],
    ),
  );
}

final class _DigitKey extends StatelessWidget {
  const _DigitKey(this.digit, this.onDigit, this.size);

  final String digit;
  final ValueChanged<String> onDigit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          onDigit(digit);
        },
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Text(
              digit,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _IconKey extends StatelessWidget {
  const _IconKey({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
