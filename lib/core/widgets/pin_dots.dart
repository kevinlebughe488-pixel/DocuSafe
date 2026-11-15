import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_spacing.dart';

/// Points de saisie du code (docs/07-design.md §7.2).
///
/// Affiche au moins six points ; au-delà, un point par chiffre saisi.
final class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filled,
    this.minDots = 6,
    this.hasError = false,
  });

  final int filled;
  final int minDots;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = filled > minDots ? filled : minDots;
    final activeColor = hasError ? scheme.error : scheme.primary;
    return Semantics(
      label: '$filled chiffres saisis',
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? activeColor : Colors.transparent,
                border: Border.all(
                  color: i < filled ? activeColor : scheme.outline,
                  width: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
