import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/daos/documents_dao.dart';
import '../utils/date_only.dart';
import 'document_repository_streams.dart';

/// Tri d'une liste de documents.
enum DocumentSort { newest, oldest, title, expiration }

/// Filtre d'une liste de documents.
final class DocumentFilter {
  const DocumentFilter({
    this.categoryId,
    this.favoritesOnly = false,
    this.sort = DocumentSort.newest,
  });

  final String? categoryId;
  final bool favoritesOnly;
  final DocumentSort sort;

  DocumentFilter copyWith({
    String? categoryId,
    bool clearCategory = false,
    bool? favoritesOnly,
    DocumentSort? sort,
  }) => DocumentFilter(
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    sort: sort ?? this.sort,
  );
}

/// Fiche complète : document, catégorie et tags.
final class DocumentDetail {
  const DocumentDetail({
    required this.document,
    required this.category,
    required this.tags,
  });

  final DocumentRow document;
  final CategoryRow category;
  final List<TagRow> tags;
}

/// Accès aux documents pour les écrans : listes observées, fiche, édition.
/// Les opérations lourdes (chiffrement, suppression des fichiers) sont dans
/// les cas d'utilisation dédiés.
final class DocumentRepository {
  const DocumentRepository(this._db);

  final AppDatabase _db;

  Stream<List<DocumentRow>> watchList(DocumentFilter filter) {
    final query = _db.select(_db.documents);
    if (filter.categoryId != null) {
      query.where((d) => d.categoryId.equals(filter.categoryId!));
    }
    if (filter.favoritesOnly) {
      query.where((d) => d.isFavorite.equals(true));
    }
    query.orderBy(switch (filter.sort) {
      DocumentSort.newest => [(d) => OrderingTerm.desc(d.createdAt)],
      DocumentSort.oldest => [(d) => OrderingTerm.asc(d.createdAt)],
      DocumentSort.title => [
        (d) => OrderingTerm.asc(d.title.collate(Collate.noCase)),
      ],
      DocumentSort.expiration => [
        (d) => OrderingTerm(expression: d.expirationDate.isNull()),
        (d) => OrderingTerm.asc(d.expirationDate),
      ],
    });
    return query.watch();
  }

  /// Documents ajoutés récemment, les plus récents d'abord.
  Stream<List<DocumentRow>> watchRecentlyAdded({int limit = 20}) =>
      (_db.select(_db.documents)
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)])
            ..limit(limit))
          .watch();

  /// Documents consultés récemment, les plus récents d'abord.
  Stream<List<DocumentRow>> watchRecentlyOpened({int limit = 20}) =>
      (_db.select(_db.documents)
            ..where((d) => d.lastOpenedAt.isNotNull())
            ..orderBy([(d) => OrderingTerm.desc(d.lastOpenedAt)])
            ..limit(limit))
          .watch();

  Stream<List<DocumentRow>> watchFavorites({int? limit}) {
    final query = _db.select(_db.documents)
      ..where((d) => d.isFavorite.equals(true))
      ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.watch();
  }

  /// Documents dont la date d'expiration est renseignée, par urgence.
  Stream<List<DocumentRow>> watchExpiring({int? limit}) {
    final query = _db.select(_db.documents)
      ..where((d) => d.expirationDate.isNotNull())
      ..orderBy([(d) => OrderingTerm.asc(d.expirationDate)]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.watch();
  }

  Stream<DocumentRow?> watchDocument(String id) =>
      (_db.select(_db.documents)..where((d) => d.id.equals(id))).watchSingleOrNull();

  /// Fiche complète, mise à jour quand le document, sa catégorie ou ses
  /// tags changent.
  Stream<DocumentDetail?> watchDetail(String id) {
    final docQuery = _db.select(_db.documents).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.documents.categoryId),
      ),
    ])..where(_db.documents.id.equals(id));
    final tagQuery = _db.select(_db.tags).join([
      innerJoin(_db.documentTags, _db.documentTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.documentTags.documentId.equals(id));

    return combineLatest2(
      docQuery.watchSingleOrNull(),
      tagQuery.map((r) => r.readTable(_db.tags)).watch(),
      (row, tags) => row == null
          ? null
          : DocumentDetail(
              document: row.readTable(_db.documents),
              category: row.readTable(_db.categories),
              tags: tags..sort((a, b) => a.name.compareTo(b.name)),
            ),
    );
  }

  Future<List<TagRow>> tagsOf(String id) => _db.documentsDao.tagsOf(id);

  /// Tous les tags existants, pour les suggestions.
  Future<List<String>> allTagNames() async =>
      (await (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get())
          .map((t) => t.name)
          .toList();

  Future<void> setFavorite(String id, bool value) =>
      _db.documentsDao.setFavorite(id, value);

  /// Modifie les informations d'un document (pas son fichier).
  Future<void> updateInfo(
    String id, {
    required String title,
    required String categoryId,
    String? docType,
    String? description,
    DateOnly? issueDate,
    DateOnly? expirationDate,
    required List<String> tags,
  }) {
    final cleanTitle = title.trim();
    return _db.documentsDao.updateDocument(
      id,
      DocumentsCompanion(
        title: Value(cleanTitle),
        categoryId: Value(categoryId),
        docType: Value(_clean(docType)),
        description: Value(_clean(description)),
        issueDate: Value(issueDate),
        expirationDate: Value(expirationDate),
      ),
      tagNames: tags,
    );
  }

  Future<void> moveToCategory(String id, String categoryId) =>
      _db.documentsDao.updateDocument(
        id,
        DocumentsCompanion(categoryId: Value(categoryId)),
      );

  static String? _clean(String? value) {
    final v = value?.trim();
    return v == null || v.isEmpty ? null : v;
  }
}

/// Document et tags pour une liste (sans la catégorie).
typedef DocumentListItem = DocumentWithTags;
