import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/ds_colors.dart';
import '../utils/formats.dart';

enum StatusBadgeKind { neutral, warning, error, security }

/// Étiquette d'état : « Expiré », « J-7 », « 3 mois », « 2 pages ».
/// La couleur n'est jamais seule : il y a toujours un texte.
final class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.kind = StatusBadgeKind.neutral,
    this.icon,
  });

  /// Étiquette d'une échéance.
  factory StatusBadge.expiry(ExpiryInfo info) => StatusBadge(
    label: info.label,
    kind: switch (info.status) {
      ExpiryStatus.expired => StatusBadgeKind.error,
      ExpiryStatus.soon => StatusBadgeKind.warning,
      ExpiryStatus.later => StatusBadgeKind.neutral,
    },
  );

  final String label;
  final StatusBadgeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ds = context.dsColors;
    final (bg, fg) = switch (kind) {
      StatusBadgeKind.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      StatusBadgeKind.warning => (ds.warningContainer, ds.onWarningContainer),
      StatusBadgeKind.error => (scheme.errorContainer, scheme.onErrorContainer),
      StatusBadgeKind.security => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
