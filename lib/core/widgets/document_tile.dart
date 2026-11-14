import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/app_spacing.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../documents/file_formats.dart';
import '../utils/date_only.dart';
import '../utils/formats.dart';
import 'document_thumbnail.dart';
import 'status_badge.dart';

/// Ligne de document : miniature, nom, détails, élément de fin
/// (étoile si favori, étiquette d'échéance, ou texte).
final class DocumentTile extends ConsumerWidget {
  const DocumentTile({
    super.key,
    required this.document,
    this.categoryName,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showFavorite = true,
  });

  final DocumentRow document;

  /// Nom de la catégorie (affiché dans la seconde ligne si fourni).
  final String? categoryName;

  /// Seconde ligne imposée (sinon : catégorie · format · pages).
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final parts = <String>[
      ?categoryName,
      document.fileType.format.label,
      if (document.pageCount != null && document.fileType == DocumentFileType.pdf)
        l10n.pageCount(document.pageCount!),
    ];
    final expiration = document.expirationDate;
    Widget? trail = trailing;
    if (trail == null && expiration != null) {
      final info = ExpiryInfo.of(l10n, expiration, DateOnly.today());
      if (info.status != ExpiryStatus.later) {
        trail = StatusBadge.expiry(info);
      }
    }
    if (trail == null && showFavorite && document.isFavorite) {
      trail = Icon(Icons.star_rounded, color: scheme.primary);
    }
    return ListTile(
      leading: DocumentThumbnail(document: document),
      title: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle ?? parts.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trail,
      minVerticalPadding: AppSpacing.sm,
      onTap: onTap,
    );
  }
}
