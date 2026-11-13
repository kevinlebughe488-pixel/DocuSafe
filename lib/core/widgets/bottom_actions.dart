import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_spacing.dart';

/// Zone de boutons fixée en bas d'un écran, au-dessus de la barre système.
final class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.sm,
        AppSpacing.screenMargin,
        AppSpacing.screenMargin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            children[i],
          ],
        ],
      ),
    ),
  );
}

/// Grand bouton plein (hauteur 56) : action unique en bas d'un écran d'étape.
final class LargeFilledButton extends StatelessWidget {
  const LargeFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppSpacing.largeButtonHeight),
    );
    if (icon == null) {
      return FilledButton(style: style, onPressed: onPressed, child: Text(label));
    }
    return FilledButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
