import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/app_spacing.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../providers.dart';

/// Tailles de miniature (docs/07-design.md §7.2).
enum ThumbnailSize { sm, md, lg, xl }

/// Miniature chiffrée, déchiffrée à l'affichage et gardée en cache.
/// Sans miniature : icône du format sur fond neutre.
final class DocumentThumbnail extends ConsumerWidget {
  const DocumentThumbnail({
    super.key,
    required this.document,
    this.size = ThumbnailSize.sm,
  });

  final DocumentRow document;
  final ThumbnailSize size;

  (double, double, double) get _dims => switch (size) {
    ThumbnailSize.sm => (48, 64, 6),
    ThumbnailSize.md => (72, 96, AppRadius.chip),
    ThumbnailSize.lg => (104, 138, AppRadius.chip),
    ThumbnailSize.xl => (150, 200, 10),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (w, h, radius) = _dims;
    final scheme = Theme.of(context).colorScheme;
    final thumb = ref.watch(thumbnailProvider(document.id));
    final bytes = thumb.value;
    return Semantics(
      label: AppLocalizations.of(context).documentThumbnailSemantics(document.title),
      image: true,
      child: Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: bytes != null
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: (w * MediaQuery.devicePixelRatioOf(context)).round(),
              )
            : Icon(
                document.fileType == DocumentFileType.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                size: w * 0.45,
                color: scheme.onSurfaceVariant,
              ),
      ),
    );
  }
}
