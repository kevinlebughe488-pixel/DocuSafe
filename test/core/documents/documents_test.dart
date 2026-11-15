import 'dart:io';
import 'dart:typed_data';

import 'package:docusafe/core/config/app_config.dart';
import 'package:docusafe/core/database/app_database.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/database/tables.dart';
import 'package:docusafe/core/documents/delete_document.dart';
import 'package:docusafe/core/documents/document_repository.dart';
import 'package:docusafe/core/documents/file_formats.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/documents/open_document.dart';
import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/security/auth/pin_attempts.dart';
import 'package:docusafe/core/security/crypto/argon2_params.dart';
import 'package:docusafe/core/security/crypto/dart_crypto_engine.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/lock/vault_session.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/core/storage/vault_paths.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests du chemin unique d'ajout d'un document et de sa lecture
/// (docs/02-architecture.md §7, docs/04-securite.md §8 et §20).
void main() {
  late Directory root;
  late VaultPaths paths;
  late VaultSession session;
  late IngestDocument ingest;
  late OpenDocument open;

  final fixtures = Directory('test/fixtures');

  Future<File> copyFixture(String name, [String? as]) async {
    await paths.secureTempDir.create(recursive: true);
    return File('${fixtures.path}/$name').copy(
      '${paths.secureTempDir.path}/${as ?? name}',
    );
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('docs_test');
    paths = VaultPaths.under(root);
    final store = InMemorySecureStore();
    final service = VaultService(
      crypto: const DartCryptoEngine(),
      store: store,
      biometricStore: null,
      paths: paths,
      attempts: PinAttempts(store),
      argon2Params: Argon2Params.testOnly,
    );
    session = await service.commitSetup(await service.prepareSetup('204915'));
    ingest = IngestDocument(
      session: session,
      paths: paths,
      thumbnails: const ImageOnlyThumbnailService(),
    );
    open = OpenDocument(session: session, paths: paths);
  });

  tearDown(() async {
    await session.close();
    await root.delete(recursive: true);
  });

  test('détection des formats par signature', () async {
    expect(
      (await FileFormats.detectFile(File('${fixtures.path}/rouge.png')))?.type,
      DocumentFileType.png,
    );
    expect(
      (await FileFormats.detectFile(File('${fixtures.path}/simple.pdf')))?.type,
      DocumentFileType.pdf,
    );
    expect(await FileFormats.detectFile(File('${fixtures.path}/notes.txt')), isNull);
    expect(FileFormats.detect([0xFF, 0xD8, 0xFF, 0xE0])?.type, DocumentFileType.jpeg);
    // Une extension trompeuse ne change rien : seul le contenu compte.
    final fake = await copyFixture('notes.txt', 'facture.pdf');
    expect(await ingest.check(fake), isA<FileRejected>());
  });

  test('vérification : refus clairs et doublon', () async {
    final txt = await copyFixture('notes.txt');
    expect(
      (await ingest.check(txt) as FileRejected).reason,
      FileRejectReason.unsupportedFormat,
    );
    final empty = File('${paths.secureTempDir.path}/vide.pdf')..writeAsBytesSync([]);
    expect((await ingest.check(empty) as FileRejected).reason, FileRejectReason.empty);
    expect(
      (await ingest.check(File('${root.path}/absent.pdf')) as FileRejected).reason,
      FileRejectReason.unreadable,
    );

    final png = await copyFixture('rouge.png');
    final check = await ingest.check(png) as FileAccepted;
    expect(check.format.type, DocumentFileType.png);
    expect(check.size, png.lengthSync());
    expect(check.isDuplicate, isFalse);
    expect(check.preview.thumbnailJpeg, isNotNull);
    expect(check.preview.pageCount, 1);
    // Miniature : JPEG, au plus 512 px (640 → 512).
    expect(check.preview.thumbnailJpeg!.sublist(0, 3), [0xFF, 0xD8, 0xFF]);

    await ingest(
      IngestRequest(
        source: png,
        fileName: 'rouge.png',
        check: check,
        title: 'Photo rouge',
        categoryId: DefaultCategory.othersId,
      ),
    );
    final again = await copyFixture('rouge.png');
    final second = await ingest.check(again) as FileAccepted;
    expect(second.isDuplicate, isTrue);
    expect(second.duplicateOf!.title, 'Photo rouge');
  });

  test('ingestion : fichier chiffré, miniature, base, nettoyage', () async {
    final pdf = await copyFixture('simple.pdf');
    final plainBytes = pdf.readAsBytesSync();
    final check = await ingest.check(pdf) as FileAccepted;
    final stages = <IngestStage>[];
    final row = await ingest(
      IngestRequest(
        source: pdf,
        fileName: 'simple.pdf',
        check: check,
        title: '  Contrat de bail ',
        categoryId: 'default-housing',
        docType: 'Bail',
        expirationDate: const DateOnly(2027, 8, 31),
        tags: ['logement', 'Logement', 'important'],
      ),
      onStage: stages.add,
    );
    expect(stages, IngestStage.values);
    expect(row.title, 'Contrat de bail');
    expect(row.fileType, DocumentFileType.pdf);
    expect(row.fileSize, plainBytes.length);
    expect(row.integrityHash, check.sha256Hex);
    expect(row.expirationDate, const DateOnly(2027, 8, 31));
    expect((await session.database.documentsDao.tagsOf(row.id)).length, 2);

    // Le clair a disparu ; le fichier chiffré ne contient ni la signature PDF
    // ni le texte du document ; pas de fichier provisoire.
    expect(pdf.existsSync(), isFalse);
    final encrypted = paths.fileFor(row.encryptedFilePath);
    expect(encrypted.existsSync(), isTrue);
    final cipherBytes = encrypted.readAsBytesSync();
    expect(String.fromCharCodes(cipherBytes.sublist(0, 4)), 'DSF1');
    expect(String.fromCharCodes(cipherBytes).contains('%PDF'), isFalse);
    expect(String.fromCharCodes(cipherBytes).contains('DocSafe'), isFalse);
    expect(File('${encrypted.path}.part').existsSync(), isFalse);
    // Pas de miniature pour un PDF avec le service « images seulement ».
    expect(paths.fileFor(VaultPaths.thumbnailRelativePath(row.id)).existsSync(), isFalse);

    // Ouverture : contenu identique, « consulté » renseigné.
    final opened = await open(row);
    expect(await opened.readAll(), plainBytes);
    expect(opened.tempFile, isNull);
    await opened.dispose();
    final reread = (await session.database.documentsDao.getById(row.id))!;
    expect(reread.lastOpenedAt, isNotNull);
  });

  test('miniature chiffrée et relue', () async {
    final png = await copyFixture('rouge.png');
    final check = await ingest.check(png) as FileAccepted;
    final row = await ingest(
      IngestRequest(
        source: png,
        fileName: 'rouge.png',
        check: check,
        title: 'Photo',
        categoryId: DefaultCategory.othersId,
      ),
    );
    final thumbFile = paths.fileFor(VaultPaths.thumbnailRelativePath(row.id));
    expect(thumbFile.existsSync(), isTrue);
    expect(String.fromCharCodes(thumbFile.readAsBytesSync().sublist(0, 4)), 'DSF1');
    final thumb = await open.thumbnail(row);
    expect(thumb, check.preview.thumbnailJpeg);
  });

  test('fichier altéré ou remplacé : refusé à la lecture', () async {
    final pdf = await copyFixture('simple.pdf');
    final check = await ingest.check(pdf) as FileAccepted;
    final row = await ingest(
      IngestRequest(
        source: pdf,
        fileName: 'simple.pdf',
        check: check,
        title: 'Bail',
        categoryId: 'default-housing',
      ),
    );
    final encrypted = paths.fileFor(row.encryptedFilePath);
    final bytes = encrypted.readAsBytesSync();
    bytes[bytes.length - 20] ^= 0x01;
    encrypted.writeAsBytesSync(bytes);
    await expectLater(open(row), throwsA(same(CryptoException.integrity)));

    // Fichier remplacé par un autre document chiffré avec la même clé :
    // l'empreinte en base ne correspond plus.
    final png = await copyFixture('rouge.png');
    final check2 = await ingest.check(png) as FileAccepted;
    final other = await ingest(
      IngestRequest(
        source: png,
        fileName: 'rouge.png',
        check: check2,
        title: 'Photo',
        categoryId: DefaultCategory.othersId,
      ),
    );
    paths.fileFor(other.encryptedFilePath).copySync(encrypted.path);
    await expectLater(open(row), throwsA(same(CryptoException.integrity)));

    encrypted.deleteSync();
    await expectLater(open(row), throwsA(isA<StorageException>()));
  });

  test('gros fichier : déchiffré dans un fichier temporaire', () async {
    final big = File('${paths.secureTempDir.path}/gros.png');
    final header = File('${fixtures.path}/rouge.png').readAsBytesSync();
    // En-tête PNG valide suivi de données de remplissage : le format est
    // reconnu par la signature, la taille dépasse la limite mémoire.
    final sink = big.openWrite();
    sink.add(header);
    final filler = Uint8List(1000 * 1000);
    for (var i = 0; i < (DocumentLimits.maxInMemoryBytes ~/ filler.length) + 1; i++) {
      sink.add(filler);
    }
    await sink.close();
    final check = await ingest.check(big) as FileAccepted;
    final row = await ingest(
      IngestRequest(
        source: big,
        fileName: 'gros.png',
        check: check,
        title: 'Gros',
        categoryId: DefaultCategory.othersId,
      ),
    );
    final opened = await open(row);
    expect(opened.bytes, isNull);
    expect(opened.tempFile, isNotNull);
    expect(opened.tempFile!.lengthSync(), row.fileSize);
    expect(opened.tempFile!.path.startsWith(paths.secureTempDir.path), isTrue);
    await opened.dispose();
    expect(opened.tempFile!.existsSync(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('suppression : base et fichiers', () async {
    final png = await copyFixture('rouge.png');
    final check = await ingest.check(png) as FileAccepted;
    final row = await ingest(
      IngestRequest(
        source: png,
        fileName: 'rouge.png',
        check: check,
        title: 'Photo',
        categoryId: DefaultCategory.othersId,
        tags: ['a'],
      ),
    );
    await DeleteDocument(session: session, paths: paths)(row);
    expect(await session.database.documentsDao.getById(row.id), isNull);
    expect(paths.fileFor(row.encryptedFilePath).existsSync(), isFalse);
    expect(paths.fileFor(VaultPaths.thumbnailRelativePath(row.id)).existsSync(), isFalse);
    expect(await session.database.documentsDao.searchIds('photo'), isEmpty);
  });

  test('dépôt : listes, tri, fiche, modification', () async {
    final repo = DocumentRepository(session.database);
    Future<DocumentRow> add(String title, String category, {DateOnly? exp}) async {
      final f = await copyFixture('simple.pdf', '$title.pdf');
      final check = await ingest.check(f) as FileAccepted;
      return ingest(
        IngestRequest(
          source: f,
          fileName: '$title.pdf',
          check: check,
          title: title,
          categoryId: category,
          expirationDate: exp,
        ),
      );
    }

    // Même contenu, mais l'empreinte sert au doublon, pas à l'unicité :
    // trois documents distincts peuvent partager un fichier identique.
    final a = await add('Bail', 'default-housing', exp: const DateOnly(2027, 8, 31));
    final b = await add('Assurance', 'default-housing', exp: const DateOnly(2026, 12, 1));
    final c = await add('Zèbre', DefaultCategory.othersId);

    expect(
      (await repo.watchList(const DocumentFilter()).first).map((d) => d.id),
      [c.id, b.id, a.id],
    );
    expect(
      (await repo.watchList(const DocumentFilter(sort: DocumentSort.title)).first)
          .map((d) => d.title),
      ['Assurance', 'Bail', 'Zèbre'],
    );
    expect(
      (await repo.watchList(const DocumentFilter(sort: DocumentSort.expiration)).first)
          .map((d) => d.title),
      ['Assurance', 'Bail', 'Zèbre'],
    );
    expect(
      (await repo.watchList(const DocumentFilter(categoryId: 'default-housing')).first)
          .length,
      2,
    );
    await repo.setFavorite(c.id, true);
    expect((await repo.watchFavorites().first).single.id, c.id);
    expect((await repo.watchRecentlyOpened().first), isEmpty);
    final opened = await open(c);
    await opened.dispose();
    expect((await repo.watchRecentlyOpened().first).single.id, c.id);

    await repo.updateInfo(
      a.id,
      title: 'Bail 2027',
      categoryId: DefaultCategory.othersId,
      docType: 'Bail',
      description: ' Appartement ',
      issueDate: const DateOnly(2024, 9, 1),
      expirationDate: const DateOnly(2027, 8, 31),
      tags: ['logement'],
    );
    final detail = (await repo.watchDetail(a.id).first)!;
    expect(detail.document.title, 'Bail 2027');
    expect(detail.document.description, 'Appartement');
    expect(detail.category.id, DefaultCategory.othersId);
    expect(detail.tags.map((t) => t.name), ['logement']);
    expect(await repo.allTagNames(), ['logement']);
    expect(await repo.watchDetail('inconnu').first, isNull);
  });
}
