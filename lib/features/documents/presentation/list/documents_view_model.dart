import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/documents/document_repository.dart';
import '../../../../core/providers.dart';
import '../../../../core/security/lock/vault_state.dart';

/// Onglets de l'écran Documents.
enum DocumentsTab { all, favorites, recent }

/// Vue « Récents » : ajoutés ou consultés.
enum RecentMode { added, opened }

/// Filtre courant de l'écran Documents (catégorie, tri, vue récente).
final class DocumentsFilterState {
  const DocumentsFilterState({
    this.categoryId,
    this.sort = DocumentSort.newest,
    this.recentMode = RecentMode.added,
  });

  final String? categoryId;
  final DocumentSort sort;
  final RecentMode recentMode;

  DocumentsFilterState copyWith({
    String? categoryId,
    bool clearCategory = false,
    DocumentSort? sort,
    RecentMode? recentMode,
  }) => DocumentsFilterState(
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    sort: sort ?? this.sort,
    recentMode: recentMode ?? this.recentMode,
  );
}

final class DocumentsFilterNotifier extends Notifier<DocumentsFilterState> {
  @override
  DocumentsFilterState build() => const DocumentsFilterState();

  void setCategory(String? id) => state = id == null
      ? state.copyWith(clearCategory: true)
      : state.copyWith(categoryId: id);

  void setSort(DocumentSort sort) => state = state.copyWith(sort: sort);

  void setRecentMode(RecentMode mode) => state = state.copyWith(recentMode: mode);
}

final documentsFilterProvider =
    NotifierProvider<DocumentsFilterNotifier, DocumentsFilterState>(
      DocumentsFilterNotifier.new,
    );

/// Liste « Tous », filtrée et triée.
final allDocumentsProvider = StreamProvider<List<DocumentRow>>((ref) {
  if (ref.watch(vaultControllerProvider) is! VaultUnlocked) {
    return const Stream.empty();
  }
  final filter = ref.watch(documentsFilterProvider);
  return ref.watch(documentRepositoryProvider).watchList(
    DocumentFilter(categoryId: filter.categoryId, sort: filter.sort),
  );
});

final favoriteDocumentsProvider = StreamProvider<List<DocumentRow>>((ref) {
  if (ref.watch(vaultControllerProvider) is! VaultUnlocked) {
    return const Stream.empty();
  }
  return ref.watch(documentRepositoryProvider).watchFavorites();
});

final recentDocumentsProvider = StreamProvider<List<DocumentRow>>((ref) {
  if (ref.watch(vaultControllerProvider) is! VaultUnlocked) {
    return const Stream.empty();
  }
  final repo = ref.watch(documentRepositoryProvider);
  return switch (ref.watch(documentsFilterProvider).recentMode) {
    RecentMode.added => repo.watchRecentlyAdded(limit: 50),
    RecentMode.opened => repo.watchRecentlyOpened(limit: 50),
  };
});

/// Catégories par identifiant, pour afficher le nom dans les listes.
final categoriesByIdProvider = StreamProvider<Map<String, CategoryRow>>((ref) {
  final state = ref.watch(vaultControllerProvider);
  if (state is! VaultUnlocked) {
    return const Stream.empty();
  }
  return state.session.database.categoriesDao.watchAll().map(
    (list) => {for (final c in list) c.id: c},
  );
});
