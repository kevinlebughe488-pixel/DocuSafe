import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/ds_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/documents/export_document.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/app_log.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../documents/presentation/list/documents_view_model.dart';

/// Place occupée par une catégorie.
typedef CategoryUsage = ({CategoryRow category, int bytes});

/// Espace occupé par les documents, réparti par catégorie (écran 19).
final storageUsageProvider = StreamProvider<List<CategoryUsage>>((ref) {
  final categories = ref.watch(categoriesByIdProvider).value ?? const {};
  return ref.watch(databaseProvider).documentsDao.watchSizeByCategory().map(
    (sizes) {
      final usage = [
        for (final MapEntry(:key, :value) in sizes.entries)
          if (categories[key] != null && value > 0)
            (category: categories[key]!, bytes: value),
      ]..sort((a, b) => b.bytes.compareTo(a.bytes));
      return usage;
    },
  );
});

/// Taille totale des documents, en octets.
final totalSizeProvider = StreamProvider<int>(
  (ref) => ref.watch(databaseProvider).documentsDao.watchTotalSize(),
);

final documentCountProvider = StreamProvider<int>(
  (ref) => ref.watch(databaseProvider).documentsDao.watchCount(),
);

/// Espace libre sur le téléphone (`null` si inconnu).
final freeSpaceProvider = FutureProvider<int?>(
  (ref) => ref.watch(shareServiceProvider).freeBytes(),
);

/// Taille des fichiers temporaires (`secure_tmp/`).
final tempFilesSizeProvider = FutureProvider<int>((ref) async {
  final dir = ref.watch(vaultPathsProvider).secureTempDir;
  if (!await dir.exists()) {
    return 0;
  }
  var total = 0;
  await for (final f in dir.list(recursive: true)) {
    if (f is File) {
      total += await f.length();
    }
  }
  return total;
});

final class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final usage = ref.watch(storageUsageProvider).value ?? const [];
    final count = ref.watch(documentCountProvider).value ?? 0;
    final free = ref.watch(freeSpaceProvider).value;
    final temp = ref.watch(tempFilesSizeProvider).value ?? 0;
    final total = usage.fold<int>(0, (sum, u) => sum + u.bytes);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storageTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Formats.fileSize(total), style: theme.textTheme.headlineMedium),
                Text(
                  [
                    l10n.storageDocumentCount(count),
                    if (free != null) l10n.storageFree(Formats.fileSize(free)),
                  ].join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          for (final u in usage)
                            Expanded(
                              flex: (u.bytes * 1000 ~/ total).clamp(1, 1000),
                              child: ColoredBox(
                                color: context.dsColors
                                    .categoryOf(u.category.color)
                                    .reference,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          for (final u in usage)
            ListTile(
              dense: true,
              leading: Icon(
                Icons.circle,
                size: 12,
                color: context.dsColors.categoryOf(u.category.color).reference,
              ),
              title: Text(u.category.name),
              trailing: Text(
                Formats.fileSize(u.bytes),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const Divider(),
          SettingsTile(
            icon: Icons.cleaning_services_outlined,
            title: l10n.storageTempTitle,
            subtitle: temp == 0
                ? l10n.storageTempNone
                : l10n.storageTempSome(Formats.fileSize(temp)),
            trailing: FilledButton.tonal(
              onPressed: temp == 0 ? null : () => _clean(context, ref),
              child: Text(l10n.storageTempClean),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clean(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    DocumentExporter.cancelPendingDeletes();
    try {
      await ref.read(vaultPathsProvider).purgeSecureTemp();
      messenger.showSnackBar(SnackBar(content: Text(l10n.storageTempCleaned)));
    } on FileSystemException catch (e, s) {
      AppLog.error('storage.clean', e, s);
    }
    ref.invalidate(tempFilesSizeProvider);
  }
}
