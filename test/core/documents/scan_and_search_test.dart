import 'dart:io';

import 'package:docusafe/core/database/app_database.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/database/tables.dart';
import 'package:docusafe/core/documents/document_search.dart';
import 'package:docusafe/core/documents/file_formats.dart';
import 'package:docusafe/core/documents/pdf_builder.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:docusafe/core/utils/highlight.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('assemblage PDF', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('pdf_test'));
    tearDown(() => dir.delete(recursive: true));

    test('deux pages images donnent un PDF de deux pages', () async {
      final png = File('test/fixtures/rouge.png');
      final out = File('${dir.path}/scan.pdf');
      await PdfBuilder.fromImages([png, png], out);
      expect(out.existsSync(), isTrue);
      expect((await FileFormats.detectFile(out))?.type, DocumentFileType.pdf);
      final text = String.fromCharCodes(out.readAsBytesSync());
      expect(RegExp(r'/Type\s*/Page[^s]').allMatches(text).length, 2);
    });
  });

  group('mise en évidence', () {
    test('sans accents ni majuscules, en début de mot', () {
      expect(highlightRanges('Diplôme de licence', 'diplome'), [(0, 7)]);
      expect(highlightRanges('Reçu de passeport', 'PASS'), [(8, 12)]);
      expect(highlightRanges('Impasse', 'pass'), isEmpty);
      expect(highlightRanges('Carte grise', 'car gri'), [(0, 3), (6, 9)]);
      expect(highlightRanges('Bail', ''), isEmpty);
    });
  });

  group('recherche avec filtres', () {
    late AppDatabase db;
    late DocumentSearch search;
    final now = DateTime(2026, 11, 14, 12);

    Future<void> add(
      String id,
      String title, {
      String category = DefaultCategory.othersId,
      DocumentFileType type = DocumentFileType.pdf,
      bool favorite = false,
      DateTime? created,
      DateOnly? expiration,
      List<String> tags = const [],
    }) => db.documentsDao.insertDocument(
      DocumentsCompanion.insert(
        id: id,
        title: title,
        categoryId: category,
        fileName: '$id.${type.name}',
        encryptedFilePath: 'files/$id.dsf',
        fileType: type,
        fileSize: 10,
        createdAt: created ?? now,
        updatedAt: now,
        isFavorite: Value(favorite),
        expirationDate: Value(expiration),
        integrityHash: 'h$id',
      ),
      tagNames: tags,
    );

    setUp(() async {
      db = AppDatabase.inMemory();
      search = DocumentSearch(db);
      await add('p1', 'Passeport', category: 'default-identity', favorite: true,
          expiration: const DateOnly(2026, 12, 1), tags: ['voyage']);
      await add('p2', 'Reçu de passeport', category: 'default-identity',
          type: DocumentFileType.jpeg, created: now.subtract(const Duration(days: 40)));
      await add('d1', 'Diplôme de licence', category: 'default-education',
          expiration: const DateOnly(2026, 1, 1));
      await add('f1', 'Facture', type: DocumentFileType.png,
          created: now.subtract(const Duration(days: 400)), tags: ['voyage']);
    });
    tearDown(() => db.close());

    Future<List<String>> ids(String text, SearchFilters f) async =>
        (await search.search(text, f, now: now)).map((d) => d.id).toList();

    test('texte seul, sans accents', () async {
      expect((await ids('pass', const SearchFilters())).toSet(), {'p1', 'p2'});
      expect(await ids('diplome', const SearchFilters()), ['d1']);
      expect(await ids('inconnu', const SearchFilters()), isEmpty);
      expect(await ids('', const SearchFilters()), isEmpty);
    });

    test('filtres seuls et combinés', () async {
      expect(await ids('', const SearchFilters(favoritesOnly: true)), ['p1']);
      expect(await ids('', const SearchFilters(fileType: DocumentFileType.jpeg)), ['p2']);
      expect(
        await ids('pass', const SearchFilters(categoryId: 'default-identity', fileType: DocumentFileType.pdf)),
        ['p1'],
      );
      expect((await ids('', const SearchFilters(added: AddedPeriod.month))).toSet(), {'p1', 'd1'});
      expect((await ids('', const SearchFilters(added: AddedPeriod.year))).toSet(), {'p1', 'p2', 'd1'});
      expect(await ids('', const SearchFilters(expiry: ExpiryFilter.expired)), ['d1']);
      expect(await ids('', const SearchFilters(expiry: ExpiryFilter.within30Days)), ['p1']);
      expect((await ids('', const SearchFilters(expiry: ExpiryFilter.none))).toSet(), {'p2', 'f1'});
      final voyage = (await search.allTags()).single;
      expect((await ids('', SearchFilters(tagId: voyage.id))).toSet(), {'p1', 'f1'});
      expect(await ids('facture', SearchFilters(tagId: voyage.id)), ['f1']);
    });

    test('sans texte : du plus récent au plus ancien', () async {
      expect(await ids('', SearchFilters(tagId: (await search.allTags()).single.id)), ['p1', 'f1']);
    });
  });
}
