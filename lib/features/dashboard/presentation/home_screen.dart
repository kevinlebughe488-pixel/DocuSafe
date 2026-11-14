import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/categories_dao.dart';
import '../../../core/database/daos/settings_dao.dart';
import '../../../core/providers.dart';
import '../../../core/security/lock/vault_state.dart';
import '../../../core/utils/formats.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/document_thumbnail.dart';
import '../../../core/widgets/document_tile.dart';
import '../../../core/widgets/ds_logo.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/secure_label.dart';
import '../../../core/widgets/state_view.dart';
import '../../auth/presentation/reauth/reauth_sheet.dart';
import '../../documents/presentation/import/import_view_model.dart';
import '../../documents/presentation/list/documents_view_model.dart';

/// Tableau de bord (écran 5) : compteur, importation, catégories, favoris,
/// ajoutés récemment. Construit comme une liste de sections indépendantes.
/// « Scanner » arrive au lot b, « Échéances à venir » au lot c.
final class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = ref.watch(_documentCountProvider).value ?? 0;
    final totalSize = ref.watch(_totalSizeProvider).value ?? 0;
    final categories = ref.watch(_categoriesProvider);
    final favorites = ref.watch(_favoritesProvider).value ?? const [];
    final recent = ref.watch(_recentProvider).value ?? const [];
    final recoveryConfirmed = ref.watch(_recoveryConfirmedProvider).value ?? true;
    final categoryNames = ref.watch(categoriesByIdProvider).value ?? const {};

    Future<void> import() async {
      ref.read(importViewModelProvider.notifier).reset();
      await context.push(Routes.documentsImport, extra: ImportSource.files);
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const DsLogo(size: 28),
            const SizedBox(width: AppSpacing.md),
            Text(l10n.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.homeLock,
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () => ref
                .read(vaultControllerProvider.notifier)
                .lock(currentLocation: Routes.home),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeDocumentCount(count), style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                SecureLabel(
                  plural: count != 1,
                  suffix: count == 0 ? null : Formats.fileSize(totalSize),
                ),
              ],
            ),
          ),
          if (!recoveryConfirmed)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                0,
                AppSpacing.screenMargin,
                AppSpacing.lg,
              ),
              child: InfoBanner(
                kind: InfoBannerKind.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.homeRecoveryBanner),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.tonal(
                      onPressed: () async {
                        if (await requestReauth(context, ref) && context.mounted) {
                          await context.push(Routes.recoveryKeyFirstTime);
                        }
                      },
                      child: Text(l10n.homeRecoveryAction),
                    ),
                  ],
                ),
              ),
            ),
          if (count == 0)
            StateView(
              icon: Icons.inventory_2_outlined,
              title: l10n.homeEmptyTitle,
              body: l10n.homeEmptyBodyLotA,
              actions: [
                FilledButton.icon(
                  onPressed: import,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(l10n.homeImport),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                ),
                onPressed: import,
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(l10n.homeImport),
              ),
            ),
          _SectionHeader(
            title: l10n.homeCategories,
            action: l10n.homeManage,
            onAction: () => context.push(Routes.categories),
          ),
          switch (categories) {
            AsyncData(:final value) => SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => _CategoryCard(item: value[i]),
              ),
            ),
            AsyncError() => Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: Text(l10n.commonErrorBody),
            ),
            _ => const SizedBox(height: 132),
          },
          if (favorites.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.homeFavorites,
              action: l10n.homeSeeAll,
              onAction: () => context.go(Routes.documentsFavorites),
            ),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                itemCount: favorites.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => _FavoriteCard(
                  document: favorites[i],
                  categoryName: categoryNames[favorites[i].categoryId]?.name ?? '',
                ),
              ),
            ),
          ],
          if (recent.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.homeRecentlyAdded,
              action: l10n.homeSeeAll,
              onAction: () => context.go(Routes.documentsRecent),
            ),
            for (final d in recent)
              DocumentTile(
                document: d,
                categoryName: categoryNames[d.categoryId]?.name,
                trailing: Text(Formats.relativeDay(l10n, d.createdAt)),
                onTap: () => context.push(Routes.document(d.id)),
              ),
          ],
        ],
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

final class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item});

  final CategoryWithCount item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = item.category;
    return SizedBox(
      width: 140,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.go(Routes.documentsOfCategory(c.id)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryIcon(icon: c.icon, color: c.color),
                const Spacer(),
                Text(
                  c.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.homeCategoryCount(item.documentCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.document, required this.categoryName});

  final DocumentRow document;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: () => context.push(Routes.document(document.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                DocumentThumbnail(document: document, size: ThumbnailSize.lg),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.star_rounded, color: theme.colorScheme.primary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              document.title,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              categoryName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Stream<T> _whenUnlocked<T>(Ref ref, Stream<T> Function(VaultUnlocked s) build) {
  final state = ref.watch(vaultControllerProvider);
  return state is VaultUnlocked ? build(state) : const Stream.empty();
}

final _documentCountProvider = StreamProvider<int>(
  (ref) => _whenUnlocked(ref, (s) => s.session.database.documentsDao.watchCount()),
);

final _totalSizeProvider = StreamProvider<int>(
  (ref) => _whenUnlocked(ref, (s) => s.session.database.documentsDao.watchTotalSize()),
);

final _categoriesProvider = StreamProvider<List<CategoryWithCount>>(
  (ref) => _whenUnlocked(ref, (s) => s.session.database.categoriesDao.watchWithCounts()),
);

final _favoritesProvider = StreamProvider<List<DocumentRow>>(
  (ref) => _whenUnlocked(ref, (_) => ref.watch(documentRepositoryProvider).watchFavorites(limit: 10)),
);

final _recentProvider = StreamProvider<List<DocumentRow>>(
  (ref) => _whenUnlocked(ref, (_) => ref.watch(documentRepositoryProvider).watchRecentlyAdded(limit: 5)),
);

/// Vrai une fois la clé de récupération notée par l'utilisateur.
final _recoveryConfirmedProvider = StreamProvider<bool>(
  (ref) => _whenUnlocked(
    ref,
    (s) => s.session.database.settingsDao.watchFlag(VaultConfigKeys.recoveryKeyConfirmed),
  ),
);
