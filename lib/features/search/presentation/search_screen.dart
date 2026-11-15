import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/documents/document_search.dart';
import '../../../core/documents/file_formats.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/highlight.dart';
import '../../../core/widgets/document_tile.dart';
import '../../../core/widgets/state_view.dart';
import '../../documents/presentation/list/documents_view_model.dart';
import 'search_view_model.dart';

/// Recherche (écrans 12a et 12b) : résultats pendant la saisie, mots
/// trouvés mis en évidence, filtres combinables.
final class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

final class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(searchViewModelProvider);
    final vm = ref.read(searchViewModelProvider.notifier);
    final categories = ref.watch(categoriesByIdProvider).value ?? const {};

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                0,
              ),
              child: SearchBar(
                controller: _controller,
                autoFocus: true,
                hintText: l10n.searchHint,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surfaceContainerHigh),
                leading: IconButton(
                  tooltip: l10n.commonBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                trailing: [
                  if (state.text.isNotEmpty)
                    IconButton(
                      tooltip: l10n.searchClear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        vm.setText('');
                      },
                    ),
                ],
                onChanged: vm.setText,
              ),
            ),
            _FilterBar(filters: state.filters, categories: categories),
            Expanded(child: _results(context, state, categories)),
          ],
        ),
      ),
    );
  }

  Widget _results(
    BuildContext context,
    SearchState state,
    Map<String, CategoryRow> categories,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (state.error != null) {
      return StateView(
        icon: Icons.error_outline_rounded,
        title: l10n.commonErrorTitle,
        body: ErrorMessages.of(l10n, state.error!),
        isError: true,
      );
    }
    if (state.isIdle) {
      return StateView(
        icon: Icons.search_rounded,
        title: l10n.searchStartTitle,
        body: l10n.searchStartBody,
      );
    }
    if (state.results.isEmpty && !state.loading) {
      return StateView(
        icon: Icons.search_off_rounded,
        title: l10n.searchNoResultTitle,
        body: l10n.searchNoResultBody,
        actions: [
          if (!state.filters.isEmpty)
            FilledButton.tonal(
              onPressed: ref.read(searchViewModelProvider.notifier).clearFilters,
              child: Text(l10n.searchClearFilters),
            ),
        ],
      );
    }
    return ListView.builder(
      itemCount: state.results.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              AppSpacing.md,
              AppSpacing.screenMargin,
              AppSpacing.xs,
            ),
            child: Text(
              l10n.searchResults(state.results.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final doc = state.results[i - 1];
        return _ResultTile(
          document: doc,
          query: state.text,
          categoryName: categories[doc.categoryId]?.name,
        );
      },
    );
  }
}

/// Ligne de résultat : le titre met en évidence les mots trouvés.
final class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.document,
    required this.query,
    required this.categoryName,
  });

  final DocumentRow document;
  final String query;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranges = highlightRanges(document.title, query);
    final title = document.title;
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final (start, end) in ranges) {
      if (start > cursor) {
        spans.add(TextSpan(text: title.substring(cursor, start)));
      }
      spans.add(
        TextSpan(
          text: title.substring(start, end),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            backgroundColor: theme.colorScheme.primaryContainer,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
      cursor = end;
    }
    if (cursor < title.length) {
      spans.add(TextSpan(text: title.substring(cursor)));
    }
    return DocumentTile(
      document: document,
      categoryName: categoryName,
      titleSpan: ranges.isEmpty ? null : TextSpan(children: spans),
      onTap: () => context.push(Routes.document(document.id)),
    );
  }
}

/// Puces de filtre : catégorie, tag, favoris, format, ajout, expiration.
final class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filters, required this.categories});

  final SearchFilters filters;
  final Map<String, CategoryRow> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.read(searchViewModelProvider.notifier);
    final tags = ref.watch(searchTagsProvider).value ?? const [];

    Future<T?> pick<T>(String title, List<(T?, String)> options, T? current) =>
        showModalBottomSheet<T?>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
                ),
                for (final (value, label) in options)
                  ListTile(
                    title: Text(label),
                    trailing: value == current ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.of(ctx).pop(value),
                  ),
              ],
            ),
          ),
        ).then((v) => v);

    String? tagName(String? id) => tags.where((t) => t.id == id).firstOrNull?.name;

    final addedLabel = switch (filters.added) {
      AddedPeriod.week => l10n.searchAddedWeek,
      AddedPeriod.month => l10n.searchAddedMonth,
      AddedPeriod.year => l10n.searchAddedYear,
      null => l10n.searchFilterAdded,
    };
    final expiryLabel = switch (filters.expiry) {
      ExpiryFilter.expired => l10n.searchExpiryExpired,
      ExpiryFilter.within30Days => l10n.searchExpiry30,
      ExpiryFilter.within1Year => l10n.searchExpiry365,
      ExpiryFilter.none => l10n.searchExpiryNone,
      null => l10n.searchFilterExpiry,
    };

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
      bool dropdown = true,
    }) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (dropdown) ...[
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, size: 18),
            ],
          ],
        ),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.sm,
        ),
        children: [
          chip(
            label: categories[filters.categoryId]?.name ?? l10n.searchFilterCategory,
            selected: filters.categoryId != null,
            onTap: () async {
              final v = await pick<String>(l10n.searchFilterCategory, [
                (null, l10n.searchAny),
                for (final c in categories.values) (c.id, c.name),
              ], filters.categoryId);
              if (context.mounted) {
                vm.setFilters(v == null
                    ? filters.copyWith(clearCategory: true)
                    : filters.copyWith(categoryId: v));
              }
            },
          ),
          chip(
            label: tagName(filters.tagId) ?? l10n.searchFilterTag,
            selected: filters.tagId != null,
            onTap: () async {
              if (tags.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.searchNoTags)),
                );
                return;
              }
              final v = await pick<String>(l10n.searchFilterTag, [
                (null, l10n.searchAny),
                for (final t in tags) (t.id, t.name),
              ], filters.tagId);
              vm.setFilters(v == null
                  ? filters.copyWith(clearTag: true)
                  : filters.copyWith(tagId: v));
            },
          ),
          chip(
            label: l10n.searchFilterFavorites,
            selected: filters.favoritesOnly,
            dropdown: false,
            onTap: () => vm.setFilters(filters.copyWith(favoritesOnly: !filters.favoritesOnly)),
          ),
          chip(
            label: filters.fileType?.format.label ?? l10n.searchFilterFormat,
            selected: filters.fileType != null,
            onTap: () async {
              final v = await pick<DocumentFileType>(l10n.searchFilterFormat, [
                (null, l10n.searchAny),
                for (final f in FileFormats.all) (f.type, f.label),
              ], filters.fileType);
              vm.setFilters(v == null
                  ? filters.copyWith(clearFileType: true)
                  : filters.copyWith(fileType: v));
            },
          ),
          chip(
            label: addedLabel,
            selected: filters.added != null,
            onTap: () async {
              final v = await pick<AddedPeriod>(l10n.searchFilterAdded, [
                (null, l10n.searchAny),
                (AddedPeriod.week, l10n.searchAddedWeek),
                (AddedPeriod.month, l10n.searchAddedMonth),
                (AddedPeriod.year, l10n.searchAddedYear),
              ], filters.added);
              vm.setFilters(v == null
                  ? filters.copyWith(clearAdded: true)
                  : filters.copyWith(added: v));
            },
          ),
          chip(
            label: expiryLabel,
            selected: filters.expiry != null,
            onTap: () async {
              final v = await pick<ExpiryFilter>(l10n.searchFilterExpiry, [
                (null, l10n.searchAny),
                (ExpiryFilter.expired, l10n.searchExpiryExpired),
                (ExpiryFilter.within30Days, l10n.searchExpiry30),
                (ExpiryFilter.within1Year, l10n.searchExpiry365),
                (ExpiryFilter.none, l10n.searchExpiryNone),
              ], filters.expiry);
              vm.setFilters(v == null
                  ? filters.copyWith(clearExpiry: true)
                  : filters.copyWith(expiry: v));
            },
          ),
        ],
      ),
    );
  }
}
