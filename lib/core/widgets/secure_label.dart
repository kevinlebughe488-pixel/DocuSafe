import 'package:material_ui/material_ui.dart';

import '../../app/l10n/generated/app_localizations.dart';

/// Cadenas sarcelle + « Chiffré sur cet appareil » : le seul signe de
/// protection, toujours le même (docs/07-design.md §1).
final class SecureLabel extends StatelessWidget {
  const SecureLabel({super.key, this.plural = false, this.suffix});

  final bool plural;

  /// Texte ajouté après un point médian, par exemple « 312 Mo ».
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final text = plural ? l10n.secureLabelPlural : l10n.secureLabel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, size: 16, color: theme.colorScheme.tertiary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            suffix == null ? text : '$text · $suffix',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}
