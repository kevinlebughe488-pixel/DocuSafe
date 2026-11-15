import 'package:material_ui/material_ui.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/app_spacing.dart';

/// « Étape 2 sur 3 » avec barre de progression, titre et explication.
final class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.body,
  });

  final int step;
  final int total;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    // Petit écran : marges verticales réduites, pour laisser la place au
    // clavier du code.
    final compact = MediaQuery.sizeOf(context).height < 700;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
        vertical: compact ? AppSpacing.sm : AppSpacing.screenMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.setupStep(step, total),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: step / total,
                    minHeight: 4,
                    semanticsLabel: l10n.setupStep(step, total),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
