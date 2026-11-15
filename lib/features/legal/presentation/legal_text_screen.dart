import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/info_banner.dart';

enum LegalText { privacy, terms }

/// Textes légaux consultables hors ligne, lus dans `assets/legal/`.
/// Mise en forme minimale (titres, paragraphes, listes) sans paquet tiers.
final class LegalTextScreen extends StatelessWidget {
  const LegalTextScreen({super.key, required this.text});

  final LegalText text;

  String get _asset => switch (text) {
    LegalText.privacy => 'assets/legal/confidentialite.md',
    LegalText.terms => 'assets/legal/conditions.md',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = switch (text) {
      LegalText.privacy => l10n.legalPrivacyTitle,
      LegalText.terms => l10n.legalTermsTitle,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(_asset),
        builder: (context, snapshot) {
          final content = snapshot.data;
          if (content == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            children: [
              InfoBanner.text(
                kind: InfoBannerKind.info,
                text: l10n.legalDraftNotice,
              ),
              const SizedBox(height: AppSpacing.lg),
              ..._render(context, content),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _render(BuildContext context, String markdown) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('# ')) {
        continue; // Le titre principal est dans la barre supérieure.
      }
      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
            child: Text(line.substring(3), style: theme.textTheme.titleMedium),
          ),
        );
      } else if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: _rich(theme, line.substring(2))),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _rich(theme, line),
          ),
        );
      }
    }
    return widgets;
  }

  /// Gras entre doubles astérisques, le reste en texte courant.
  static Widget _rich(ThemeData theme, String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w600) : null,
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      style: theme.textTheme.bodyMedium,
    );
  }
}
