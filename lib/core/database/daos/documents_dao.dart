import 'package:drift/drift.dart';

import '../../utils/secure_random.dart';
import '../../utils/text_normalizer.dart';
import '../app_database.dart';
import '../tables.dart';

part 'documents_dao.g.dart';

/// Document accompagné de ses tags.
final class DocumentWithTags {
  const DocumentWithTags(this.document, this.tags);

  final DocumentRow document;
  final List<TagRow> tags;
}

/// Accès aux documents, à leurs tags et à l'index de recherche.
///
/// L'index FTS5 `documents_fts` est mis à jour dans la même transaction que
/// le document : il ne peut pas se désynchroniser.
@DriftAccessor(tables: [Documents, Tags, DocumentTags, Reminders])
class DocumentsDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentsDaoMixin {
  DocumentsDao(super.db);

  Stream<int> watchCount() =>
      (selectOnly(documents)..addColumns([documents.id.count()]))
          .map((r) => r.read(documents.id.count()) ?? 0)
          .watchSingle();

  Stream<int> watchTotalSize() =>
      (selectOnly(documents)..addColumns([documents.fileSize.sum()]))
          .map((r) => r.read(documents.fileSize.sum()) ?? 0)
          .watchSingle();

  /// Taille occupée par catégorie (identifiant → octets), pour l'écran
  /// Stockage.
  Stream<Map<String, int>> watchSizeByCategory() {
    final size = documents.fileSize.sum();
    final query = selectOnly(documents)
      ..addColumns([documents.categoryId, size])
      ..groupBy([documents.categoryId]);
    return query.watch().map(
      (rows) => {
        for (final r in rows) r.read(documents.categoryId)!: r.read(size) ?? 0,
      },
    );
  }

  Future<DocumentRow?> getById(String id) =>
      (select(documents)..where((d) => d.id.equals(id))).getSingleOrNull();

  /// Un document portant la même empreinte existe-t-il déjà ? Le plus ancien
  /// est retourné si plusieurs copies ont été importées volontairement.
  Future<DocumentRow?> findByHash(String integrityHash) =>
      (select(documents)
            ..where((d) => d.integrityHash.equals(integrityHash))
            ..orderBy([(d) => OrderingTerm.asc(d.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Tous les documents, du plus récent au plus ancien.
  Future<List<DocumentRow>> getAll() => (select(
    documents,
  )..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).get();

  Stream<List<DocumentRow>> watchAll({String? categoryId}) {
    final query = select(documents)
      ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]);
    if (categoryId != null) {
      query.where((d) => d.categoryId.equals(categoryId));
    }
    return query.watch();
  }

  Future<List<TagRow>> tagsOf(String documentId) {
    final query = select(tags).join([
      innerJoin(documentTags, documentTags.tagId.equalsExp(tags.id)),
    ])..where(documentTags.documentId.equals(documentId));
    return query.map((r) => r.readTable(tags)).get();
  }

  /// Insère un document avec ses tags et sa ligne d'index, en une transaction.
  Future<void> insertDocument(
    DocumentsCompanion document, {
    List<String> tagNames = const [],
  }) async {
    await transaction(() async {
      await into(documents).insert(document);
      final tagRows = await _attachTags(document.id.value, tagNames);
      await _writeSearchRow(
        (await getById(document.id.value))!,
        tagRows.map((t) => t.name).toList(),
      );
    });
  }

  /// Met à jour un document (et éventuellement ses tags), index compris.
  Future<void> updateDocument(
    String id,
    DocumentsCompanion changes, {
    List<String>? tagNames,
  }) async {
    await transaction(() async {
      await (update(documents)..where((d) => d.id.equals(id))).write(
        changes.copyWith(updatedAt: Value(DateTime.now())),
      );
      List<TagRow> tagRows;
      if (tagNames != null) {
        await (delete(
          documentTags,
        )..where((t) => t.documentId.equals(id))).go();
        tagRows = await _attachTags(id, tagNames);
      } else {
        tagRows = await tagsOf(id);
      }
      await _writeSearchRow(
        (await getById(id))!,
        tagRows.map((t) => t.name).toList(),
      );
    });
  }

  Future<void> setFavorite(String id, bool isFavorite) =>
      (update(documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(isFavorite: Value(isFavorite)),
      );

  Future<void> markOpened(String id) =>
      (update(documents)..where((d) => d.id.equals(id))).write(
        DocumentsCompanion(lastOpenedAt: Value(DateTime.now())),
      );

  /// Supprime le document, ses liens de tags, ses rappels (cascade) et sa
  /// ligne d'index. Le fichier chiffré est supprimé par l'appelant ensuite.
  Future<void> deleteDocument(String id) async {
    await transaction(() async {
      await customStatement('DELETE FROM documents_fts WHERE document_id = ?', [
        id,
      ]);
      await (delete(documents)..where((d) => d.id.equals(id))).go();
      await _deleteOrphanTags();
    });
  }

  /// Recherche plein texte, dès les premières lettres, sans tenir compte des
  /// majuscules ni des accents. Retourne les identifiants par pertinence.
  Future<List<String>> searchIds(String query, {int limit = 100}) async {
    final match = buildMatchQuery(query);
    if (match == null) {
      return const [];
    }
    final rows = await customSelect(
      'SELECT document_id FROM documents_fts WHERE documents_fts MATCH ? '
      'ORDER BY rank LIMIT ?',
      variables: [Variable.withString(match), Variable.withInt(limit)],
    ).get();
    return rows.map((r) => r.read<String>('document_id')).toList();
  }

  /// Transforme la saisie en requête FTS5 : chaque mot devient un préfixe,
  /// les caractères spéciaux sont neutralisés. `null` si rien à chercher.
  static String? buildMatchQuery(String input) {
    final words = input
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'["*^()\-:{}]'), '').trim())
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return null;
    }
    return words.map((w) => '"$w"*').join(' ');
  }

  Future<List<TagRow>> _attachTags(
    String documentId,
    List<String> names,
  ) async {
    final result = <TagRow>[];
    final seen = <String>{};
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty || name.length > 30) {
        continue;
      }
      final key = TextNormalizer.nameKey(name);
      if (!seen.add(key)) {
        continue;
      }
      var tag = await (select(
        tags,
      )..where((t) => t.nameKey.equals(key))).getSingleOrNull();
      if (tag == null) {
        final companion = TagsCompanion.insert(
          id: SecureRandom.uuid(),
          name: name,
          nameKey: key,
        );
        await into(tags).insert(companion);
        tag = await (select(
          tags,
        )..where((t) => t.id.equals(companion.id.value))).getSingle();
      }
      await into(documentTags).insert(
        DocumentTagsCompanion.insert(documentId: documentId, tagId: tag.id),
        mode: InsertMode.insertOrIgnore,
      );
      result.add(tag);
    }
    return result;
  }

  Future<void> _deleteOrphanTags() => customStatement(
    'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM document_tags)',
  );

  Future<void> _writeSearchRow(DocumentRow doc, List<String> tagNames) async {
    await customStatement('DELETE FROM documents_fts WHERE document_id = ?', [
      doc.id,
    ]);
    await customStatement(
      'INSERT INTO documents_fts '
      '(document_id, title, doc_type, description, tags, file_name, content) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        doc.id,
        doc.title,
        doc.docType ?? '',
        doc.description ?? '',
        tagNames.join(' '),
        doc.fileName,
        doc.contentIndex ?? '',
      ],
    );
  }
}
