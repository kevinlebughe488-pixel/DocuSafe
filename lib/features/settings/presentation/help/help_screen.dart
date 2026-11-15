import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/info_banner.dart';

/// Aide et assistance (cahier des charges §3.13) : réponses aux questions
/// courantes, lisibles sans Internet. Le contact n'apparaît que lorsqu'une
/// adresse est configurée (AppConfig.supportEmail) : aucune adresse fictive.
final class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, this.supportEmail = AppConfig.supportEmail});

  /// Adresse de l'assistance (`null` : rubrique « contact » masquée).
  final String? supportEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final questions = [
      (l10n.helpForgotPinQ, l10n.helpForgotPinA),
      (l10n.helpWhereQ, l10n.helpWhereA),
      (l10n.helpNewPhoneQ, l10n.helpNewPhoneA),
      (l10n.helpRemindersQ, l10n.helpRemindersA),
      (l10n.helpScannerQ, l10n.helpScannerA),
      (l10n.helpBiometricQ, l10n.helpBiometricA),
      (l10n.helpShareQ, l10n.helpShareA),
      (l10n.helpEraseQ, l10n.helpEraseA),
    ];
    final support = supportEmail;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: InfoBanner.text(kind: InfoBannerKind.info, text: l10n.helpIntro),
          ),
          for (final (question, answer) in questions)
            ExpansionTile(
              title: Text(question, style: theme.textTheme.titleSmall),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                0,
                AppSpacing.screenMargin,
                AppSpacing.lg,
              ),
              expandedAlignment: Alignment.centerLeft,
              children: [Text(answer, style: theme.textTheme.bodyMedium)],
            ),
          if (support != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: Text(l10n.helpContactTitle),
              subtitle: Text(support),
              trailing: IconButton(
                tooltip: l10n.helpContactCopy,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: support));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.helpContactCopied)),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
