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
import '../../../core/utils/date_only.dart';
import '../../../core/utils/formats.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/document_thumbnail.dart';
import '../../../core/widgets/document_tile.dart';
import '../../../core/widgets/ds_logo.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/secure_label.dart';
import '../../../core/widgets/state_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/reauth/reauth_sheet.dart';
import '../../documents/presentation/import/import_view_model.dart';
import '../../documents/presentation/list/documents_view_model.dart';
import '../../reminders/presentation/deadlines_screen.dart';
import '../../settings/presentation/profile_name.dart';

/// Tableau de bord (écran 5) : compteur, recherche, scanner et importation,
/// catégories, favoris, ajoutés récemment. Construit comme une liste de
/// sections indépendantes, dont « Échéances à venir ».
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
    final profileName = ref.watch(profileNameProvider).value;
    final categoryNames = ref.watch(categoriesByIdProvider).value ?? const {};
    final today = DateOnly.today();
    final upcoming = (ref.watch(expiringDocumentsProvider).value ?? const <DocumentRow>[])
        .where((d) => ExpiryInfo.of(l10n, d.expirationDate!, today).status != ExpiryStatus.later)
        .take(3)
        .toList();

    Future<void> import() async {
      ref.read(importViewModelProvider.notifier).reset();
      await context.push(Routes.documentsImport, extra: ImportSource.files);
    }

    void scan() => context.go(Routes.scan);

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
                if (profileName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      l10n.homeGreeting(profileName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
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
              body: l10n.homeEmptyBodyFinal,
              actions: [
                FilledButton.icon(
                  onPressed: scan,
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: Text(l10n.homeScanDocument),
                ),
                FilledButton.tonalIcon(
                  onPressed: import,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(l10n.homeImport),
                ),
              ],
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: SearchBar(
                hintText: l10n.homeSearchHint,
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHigh),
                // Barre de lancement : la saisie se fait dans l'écran Recherche.
                onTap: () => context.push(Routes.search),
                keyboardType: TextInputType.none,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                      ),
                      onPressed: scan,
                      icon: const Icon(Icons.document_scanner_rounded),
                      label: Text(l10n.homeScan),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(AppSpacing.touchTarget),
                      ),
                      onPressed: import,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(l10n.documentsAdd),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(
              title: l10n.homeUpcomingDeadlines,
              action: l10n.homeSeeAll,
              onAction: () => context.go(Routes.deadlines),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Card(
                child: Column(
                  children: [
                    for (final d in upcoming)
                      DocumentTile(
                        document: d,
                        subtitle: l10n.expiresOn(Formats.date(d.expirationDate!)),
                        trailing: StatusBadge.expiry(ExpiryInfo.of(l10n, d.expirationDate!, today)),
                        onTap: () => context.push(Routes.document(d.id)),
                      ),
                  ],
                ),
              ),
            ),
          ],
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
