import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/l10n/generated/app_localizations.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/documents/document_repository.dart';
import '../../../../core/utils/formats.dart';
import '../../../../core/widgets/document_tile.dart';
import '../../../../core/widgets/state_view.dart';
import '../import/import_view_model.dart';
import 'documents_view_model.dart';

/// Liste des documents (écrans 6, 13, 14) : onglets Tous / Favoris /
/// Récents, filtre par catégorie, tri, bouton d'ajout.
final class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key, this.initialTab, this.initialCategoryId});

  final DocumentsTab? initialTab;
  final String? initialCategoryId;

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

final class _DocumentsScreenState extends ConsumerState<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 3,
    vsync: this,
    initialIndex: (widget.initialTab ?? DocumentsTab.all).index,
  );

  @override
  void initState() {
    super.initState();
    final category = widget.initialCategoryId;
    if (category != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(documentsFilterProvider.notifier).setCategory(category);
      });
    }
  }

  @override
  void didUpdateWidget(covariant DocumentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null && widget.initialTab != oldWidget.initialTab) {
      _tabs.animateTo(widget.initialTab!.index);
    }
    if (widget.initialCategoryId != oldWidget.initialCategoryId) {
      ref.read(documentsFilterProvider.notifier).setCategory(widget.initialCategoryId);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImportSource?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(l10n.documentsAddScan),
              onTap: () {
                Navigator.of(ctx).pop();
                context.go(Routes.scan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: Text(l10n.documentsAddFile),
              subtitle: Text(l10n.importSourceFilesSub),
              onTap: () => Navigator.of(ctx).pop(ImportSource.files),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.documentsAddPhotos),
              subtitle: Text(l10n.importSourceGallerySub),
              onTap: () => Navigator.of(ctx).pop(ImportSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source != null && mounted) {
      ref.read(importViewModelProvider.notifier).reset();
      await context.push(Routes.documentsImport, extra: source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(documentsFilterProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.documentsTitle),
        actions: [
          IconButton(
            tooltip: l10n.searchHint,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(Routes.search),
          ),
          PopupMenuButton<DocumentSort>(
            tooltip: l10n.documentsSort,
            icon: const Icon(Icons.swap_vert_rounded),
            initialValue: filter.sort,
            onSelected: ref.read(documentsFilterProvider.notifier).setSort,
            itemBuilder: (_) => [
              PopupMenuItem(value: DocumentSort.newest, child: Text(l10n.documentsSortNewest)),
              PopupMenuItem(value: DocumentSort.oldest, child: Text(l10n.documentsSortOldest)),
              PopupMenuItem(value: DocumentSort.title, child: Text(l10n.documentsSortTitle)),
              PopupMenuItem(value: DocumentSort.expiration, child: Text(l10n.documentsSortExpiration)),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.documentsTabAll),
            Tab(text: l10n.documentsTabFavorites),
            Tab(text: l10n.documentsTabRecent),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.documentsAdd,
        onPressed: _add,
        child: const Icon(Icons.add_rounded),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_AllTab(), _FavoritesTab(), _RecentTab()],
      ),
    );
  }
}

final class _AllTab extends ConsumerWidget {
  const _AllTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(documentsFilterProvider);
    final categories = ref.watch(categoriesByIdProvider).value ?? const {};
    final docs = ref.watch(allDocumentsProvider);
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
              vertical: AppSpacing.md,
            ),
            children: [
              FilterChip(
                label: Text(l10n.documentsAllCategories),
                selected: filter.categoryId == null,
                onSelected: (_) =>
                    ref.read(documentsFilterProvider.notifier).setCategory(null),
              ),
              for (final c in categories.values) ...[
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: Text(c.name),
                  selected: filter.categoryId == c.id,
                  onSelected: (_) => ref
                      .read(documentsFilterProvider.notifier)
                      .setCategory(filter.categoryId == c.id ? null : c.id),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _DocumentList(
            docs: docs,
            categories: categories,
            emptyTitle: filter.categoryId == null
                ? l10n.documentsEmptyTitle
                : l10n.documentsEmptyFilteredTitle,
            emptyBody: filter.categoryId == null
                ? l10n.documentsEmptyBody
                : l10n.documentsEmptyFilteredBody,
          ),
        ),
      ],
    );
  }
}

final class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _DocumentList(
      docs: ref.watch(favoriteDocumentsProvider),
      categories: ref.watch(categoriesByIdProvider).value ?? const {},
      emptyTitle: l10n.documentsFavoritesEmptyTitle,
      emptyBody: l10n.documentsFavoritesEmptyBody,
      emptyIcon: Icons.star_outline_rounded,
    );
  }
}

final class _RecentTab extends ConsumerWidget {
  const _RecentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(documentsFilterProvider).recentMode;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.md,
            AppSpacing.screenMargin,
            AppSpacing.sm,
          ),
          child: SegmentedButton<RecentMode>(
            segments: [
              ButtonSegment(
                value: RecentMode.added,
                label: Text(l10n.documentsRecentAdded),
              ),
              ButtonSegment(
                value: RecentMode.opened,
                label: Text(l10n.documentsRecentOpened),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(documentsFilterProvider.notifier).setRecentMode(s.first),
          ),
        ),
        Expanded(
          child: _DocumentList(
            docs: ref.watch(recentDocumentsProvider),
            categories: ref.watch(categoriesByIdProvider).value ?? const {},
            emptyTitle: l10n.documentsRecentEmptyTitle,
            emptyBody: l10n.documentsRecentEmptyBody,
            emptyIcon: Icons.history_rounded,
            subtitleOf: (d) => mode == RecentMode.opened && d.lastOpenedAt != null
                ? l10n.documentOpenedAt(
                    Formats.relativeDayTime(l10n, d.lastOpenedAt!),
                  )
                : l10n.documentAddedAt(Formats.relativeDayTime(l10n, d.createdAt)),
          ),
        ),
      ],
    );
  }
}

final class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.docs,
    required this.categories,
    required this.emptyTitle,
    required this.emptyBody,
    this.emptyIcon = Icons.folder_open_rounded,
    this.subtitleOf,
  });

  final AsyncValue<List<DocumentRow>> docs;
  final Map<String, CategoryRow> categories;
  final String emptyTitle;
  final String emptyBody;
  final IconData emptyIcon;
  final String Function(DocumentRow)? subtitleOf;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (docs) {
      AsyncData(:final value) when value.isEmpty => StateView(
        icon: emptyIcon,
        title: emptyTitle,
        body: emptyBody,
      ),
      AsyncData(:final value) => ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: value.length,
        itemBuilder: (context, i) {
          final d = value[i];
          return DocumentTile(
            document: d,
            categoryName: categories[d.categoryId]?.name,
            subtitle: subtitleOf?.call(d),
            onTap: () => context.push(Routes.document(d.id)),
          );
        },
      ),
      AsyncError() => StateView(
        icon: Icons.error_outline_rounded,
        title: l10n.commonErrorTitle,
        body: l10n.commonErrorBody,
        isError: true,
      ),
      _ => const Center(child: CircularProgressIndicator.adaptive()),
    };
  }
}
