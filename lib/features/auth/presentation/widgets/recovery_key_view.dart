import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/security/keys/recovery_key.dart';
import '../../../../core/utils/sensitive_clipboard.dart';
import '../../../../core/widgets/info_banner.dart';

/// Affichage d'une clé de récupération : encadré à chasse fixe, bouton
/// « Copier », avertissement. Affichée une seule fois.
final class RecoveryKeyView extends StatelessWidget {
  const RecoveryKeyView({super.key, required this.recoveryKey});

  final RecoveryKey recoveryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final display = recoveryKey.display;
    final lines = display.split('-');
    final firstLine = lines.take(4).join('-');
    final secondLine = lines.skip(4).join('-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.setupRecoveryKeySemantics(display),
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Text(
              '$firstLine\n$secondLine',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 1.5,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: () async {
              await SensitiveClipboard.copy(display);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.commonCopied)),
                );
              }
            },
            icon: const Icon(Icons.content_copy_rounded),
            label: Text(l10n.commonCopy),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        InfoBanner.text(
          kind: InfoBannerKind.warning,
          text: l10n.setupRecoveryWarning,
        ),
      ],
    );
  }
}
