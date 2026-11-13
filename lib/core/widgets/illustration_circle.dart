import 'package:material_ui/material_ui.dart';

/// Grande icône dans un cercle (onboarding, états vides).
final class IllustrationCircle extends StatelessWidget {
  const IllustrationCircle({
    super.key,
    required this.icon,
    this.size = 160,
    this.security = false,
  });

  final IconData icon;
  final double size;

  /// Couleurs sarcelle (ce qui touche à la protection).
  final bool security;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: security ? scheme.tertiaryContainer : scheme.primaryContainer,
        ),
        child: Icon(
          icon,
          size: size * 0.45,
          color: security ? scheme.onTertiaryContainer : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
