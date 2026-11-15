import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../utils/date_only.dart';

/// Période d'ajout d'un document.
enum AddedPeriod { week, month, year }

/// Filtre sur la date d'expiration.
enum ExpiryFilter { expired, within30Days, within1Year, none }

/// Filtres combinables de la recherche (docs/05-parcours-utilisateurs.md §7) :
/// catégorie, tag, favoris, format, période d'ajout, période d'expiration.
final class SearchFilters {
  const SearchFilters({
    this.categoryId,
    this.tagId,
    this.favoritesOnly = false,
    this.fileType,
    this.added,
    this.expiry,
  });

  final String? categoryId;
  final String? tagId;
  final bool favoritesOnly;
  final DocumentFileType? fileType;
  final AddedPeriod? added;
  final ExpiryFilter? expiry;

  bool get isEmpty =>
      categoryId == null &&
      tagId == null &&
      !favoritesOnly &&
      fileType == null &&
      added == null &&
      expiry == null;

  SearchFilters copyWith({
    String? categoryId,
    bool clearCategory = false,
    String? tagId,
    bool clearTag = false,
    bool? favoritesOnly,
    DocumentFileType? fileType,
    bool clearFileType = false,
    AddedPeriod? added,
    bool clearAdded = false,
    ExpiryFilter? expiry,
    bool clearExpiry = false,
  }) => SearchFilters(
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    tagId: clearTag ? null : (tagId ?? this.tagId),
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    fileType: clearFileType ? null : (fileType ?? this.fileType),
    added: clearAdded ? null : (added ?? this.added),
    expiry: clearExpiry ? null : (expiry ?? this.expiry),
  );
}

/// Moteur de recherche local (cahier des charges §3.8) : index plein texte
/// FTS5 de la base chiffrée (nom, type, description, tags, nom du fichier,
/// texte OCR plus tard), combiné aux filtres. Hors ligne.
final class DocumentSearch {
  const DocumentSearch(this._db);

  final AppDatabase _db;

  /// Résultats : par pertinence si un texte est saisi, sinon du plus récent
  /// au plus ancien. Liste vide si ni texte ni filtre.
  Future<List<DocumentRow>> search(
    String text,
    SearchFilters filters, {
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    List<String>? ids;
    if (text.trim().isNotEmpty) {
      ids = await _db.documentsDao.searchIds(text, limit: 500);
      if (ids.isEmpty) {
        return const [];
      }
    } else if (filters.isEmpty) {
      return const [];
    }

    final d = _db.documents;
    final query = _db.select(d);
    if (ids != null) {
      query.where((row) => row.id.isIn(ids!));
    }
    if (filters.categoryId != null) {
      query.where((row) => row.categoryId.equals(filters.categoryId!));
    }
    if (filters.favoritesOnly) {
      query.where((row) => row.isFavorite.equals(true));
    }
    if (filters.fileType != null) {
      query.where((row) => row.fileType.equalsValue(filters.fileType));
    }
    if (filters.added != null) {
      final since = current.subtract(switch (filters.added!) {
        AddedPeriod.week => const Duration(days: 7),
        AddedPeriod.month => const Duration(days: 30),
        AddedPeriod.year => const Duration(days: 365),
      });
      query.where((row) => row.createdAt.isBiggerOrEqualValue(since));
    }
    if (filters.expiry != null) {
      final today = DateOnly.fromDateTime(current).toIso();
      switch (filters.expiry!) {
        case ExpiryFilter.expired:
          query.where((row) => row.expirationDate.isSmallerThanValue(today));
        case ExpiryFilter.within30Days:
          final limit = DateOnly.fromDateTime(current).addDays(30).toIso();
          query.where(
            (row) =>
                row.expirationDate.isBiggerOrEqualValue(today) &
                row.expirationDate.isSmallerOrEqualValue(limit),
          );
        case ExpiryFilter.within1Year:
          final limit = DateOnly.fromDateTime(current).addDays(365).toIso();
          query.where(
            (row) =>
                row.expirationDate.isBiggerOrEqualValue(today) &
                row.expirationDate.isSmallerOrEqualValue(limit),
          );
        case ExpiryFilter.none:
          query.where((row) => row.expirationDate.isNull());
      }
    }
    if (filters.tagId != null) {
      final t = _db.documentTags;
      query.where(
        (row) => existsQuery(
          _db.select(t)
            ..where((x) => x.documentId.equalsExp(row.id) & x.tagId.equals(filters.tagId!)),
        ),
      );
    }

    final rows = await query.get();
    if (ids != null) {
      final rank = {for (var i = 0; i < ids.length; i++) ids[i]: i};
      rows.sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));
    } else {
      rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return rows;
  }

  /// Tous les tags, pour le filtre.
  Future<List<TagRow>> allTags() =>
      (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
}
