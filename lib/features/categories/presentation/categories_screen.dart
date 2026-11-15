import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/router/routes.dart';
import '../../../core/database/daos/categories_dao.dart';
import '../../../core/providers.dart';
import '../../../core/security/lock/vault_state.dart';
import '../../../core/widgets/category_icon.dart';

/// Catégories (écran 11a) : toucher pour modifier, glisser pour réordonner.
final class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(categoriesWithCountsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.categoryNew),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.categoriesNew),
      ),
      body: switch (categories) {
        AsyncData(:final value) => ReorderableListView.builder(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: value.length,
          onReorderItem: (from, to) => unawaited(
            ref
                .read(databaseProvider)
                .categoriesDao
                .reorder(value.map((c) => c.category.id).toList(), from, to),
          ),
          itemBuilder: (context, index) {
            final item = value[index];
            final c = item.category;
            return ListTile(
              key: ValueKey(c.id),
              leading: CategoryIcon(icon: c.icon, color: c.color),
              title: Text(c.name),
              subtitle: Text(
                c.isSystem
                    ? '${l10n.homeCategoryCount(item.documentCount)} · ${l10n.categoriesDefault}'
                    : l10n.homeCategoryCount(item.documentCount),
              ),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator_rounded),
              ),
              onTap: () => context.push(Routes.category(c.id)),
            );
          },
        ),
        AsyncError() => Center(child: Text(l10n.commonErrorBody)),
        _ => const Center(child: CircularProgressIndicator.adaptive()),
      },
    );
  }
}

/// Catégories avec leur nombre de documents, observées.
final categoriesWithCountsProvider = StreamProvider<List<CategoryWithCount>>((
  ref,
) {
  final state = ref.watch(vaultControllerProvider);
  if (state is! VaultUnlocked) {
    return const Stream.empty();
  }
  return state.session.database.categoriesDao.watchWithCounts();
});
