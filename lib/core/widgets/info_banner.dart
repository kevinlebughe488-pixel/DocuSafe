import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/ds_colors.dart';

enum InfoBannerKind { info, warning, error, security }

/// Bandeau d'information, d'avertissement, d'erreur ou de sécurité.
final class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.kind,
    required this.child,
  });

  /// Bandeau avec un texte simple.
  InfoBanner.text({Key? key, required InfoBannerKind kind, required String text})
    : this(key: key, kind: kind, child: Text(text));

  final InfoBannerKind kind;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ds = context.dsColors;
    final (background, foreground, icon) = switch (kind) {
      InfoBannerKind.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.info_outline_rounded,
      ),
      InfoBannerKind.warning => (
        ds.warningContainer,
        ds.onWarningContainer,
        Icons.warning_rounded,
      ),
      InfoBannerKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
      InfoBannerKind.security => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.lock_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.categoryIcon),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
