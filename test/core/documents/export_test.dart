import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docusafe/core/database/app_database.dart';
import 'package:docusafe/core/documents/export_document.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/security/auth/pin_attempts.dart';
import 'package:docusafe/core/security/crypto/argon2_params.dart';
import 'package:docusafe/core/security/crypto/dart_crypto_engine.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/lock/vault_session.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/core/storage/vault_paths.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sorties du coffre : partage, export d'un document, export de toutes les
/// données (docs/04-securite.md §13).
void main() {
  late Directory root;
  late VaultPaths paths;
  late VaultService service;
  late VaultSession session;
  late IngestDocument ingest;
  late DocumentExporter exporter;

  final fixtures = Directory('test/fixtures');

  Future<DocumentRow> add(String fixture, String title, String category) async {
    await paths.secureTempDir.create(recursive: true);
    final copy = await File('${fixtures.path}/$fixture').copy(
      '${paths.secureTempDir.path}/${DateTime.now().microsecondsSinceEpoch}-$fixture',
    );
    final check = await ingest.check(copy) as FileAccepted;
    return ingest(
      IngestRequest(
        source: copy,
        fileName: fixture,
        check: check,
        title: title,
        categoryId: category,
      ),
    );
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('export_test');
    paths = VaultPaths.under(root);
    final store = InMemorySecureStore();
    service = VaultService(
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
    exporter = DocumentExporter(session: session, paths: paths);
  });

  tearDown(() async {
    DocumentExporter.cancelPendingDeletes();
    await session.close();
    await root.delete(recursive: true);
  });

  test('noms de fichiers sûrs', () {
    expect(
      DocumentExporter.safeFileName('Bail 2026/2027 : "copie"'),
      'Bail 2026_2027 _ _copie_',
    );
    expect(DocumentExporter.safeFileName('..cache'), 'cache');
    expect(DocumentExporter.safeFileName('   '), 'document');
    expect(DocumentExporter.safeFileName('a' * 120).length, 80);
  });

  test(
    'partage : copie temporaire identique, purgée au verrouillage',
    () async {
      final row = await add('simple.pdf', 'Bail/2026', 'default-housing');
      final shared = await exporter.prepareForSharing(row);
      expect(shared.fileName, 'Bail_2026.pdf');
      expect(shared.mimeType, 'application/pdf');
      expect(shared.file!.path, startsWith(paths.secureTempDir.path));
      expect(
        shared.file!.readAsBytesSync(),
        File('${fixtures.path}/simple.pdf').readAsBytesSync(),
      );
      await service.purgeTemporaryFiles();
      expect(shared.file!.existsSync(), isFalse);
    },
  );

  test('export : contenu en mémoire, aucun fichier intermédiaire', () async {
    final row = await add('rouge.png', 'Photo', 'default-identity');
    final exported = await exporter.decryptForExport(row);
    expect(exported.fileName, 'Photo.png');
    expect(
      exported.bytes,
      File('${fixtures.path}/rouge.png').readAsBytesSync(),
    );
    expect(paths.secureTempDir.listSync(), isEmpty);
    exported.wipe();
    expect(exported.bytes!.every((b) => b == 0), isTrue);
  });

  test('fichier altéré : rien ne sort', () async {
    final row = await add('simple.pdf', 'Bail', 'default-housing');
    final encrypted = paths.fileFor(row.encryptedFilePath);
    final bytes = encrypted.readAsBytesSync();
    bytes[bytes.length - 20] ^= 0x01;
    encrypted.writeAsBytesSync(bytes);
    await expectLater(
      exporter.prepareForSharing(row),
      throwsA(isA<CryptoException>()),
    );
    await expectLater(
      exporter.decryptForExport(row),
      throwsA(isA<CryptoException>()),
    );
    await expectLater(
      exporter.buildArchive(
        uncategorizedFolder: 'Autres',
        archiveName: 'a.zip',
      ),
      throwsA(isA<CryptoException>()),
    );
    expect(Directory('${paths.secureTempDir.path}/share').listSync(), isEmpty);
    expect(Directory('${paths.secureTempDir.path}/export').listSync(), isEmpty);
  });

  test('export de toutes les données : ZIP rangé par catégorie', () async {
    expect(
      await exporter.buildArchive(
        uncategorizedFolder: 'Autres',
        archiveName: 'a.zip',
      ),
      isNull,
    );
    await add('simple.pdf', 'Bail', 'default-housing');
    await add('rouge.png', 'Photo', 'default-identity');
    await add('rouge.png', 'Photo', 'default-identity');
    final archive = await exporter.buildArchive(
      uncategorizedFolder: 'Autres',
      archiveName: 'DocuSafe.zip',
    );
    expect(archive!.fileName, 'DocuSafe.zip');
    expect(archive.mimeType, 'application/zip');
    final zip = ZipDecoder().decodeBytes(archive.bytes!);
    final categories = {
      for (final c in await session.database.categoriesDao.getAll())
        c.id: c.name,
    };
    final housing = categories['default-housing'];
    final identity = categories['default-identity'];
    expect(zip.files.map((f) => f.name).toSet(), {
      '$housing/Bail.pdf',
      '$identity/Photo.png',
      '$identity/Photo (2).png',
    });
    final png = zip.files.firstWhere((f) => f.name.endsWith('Photo.png'));
    expect(png.content, File('${fixtures.path}/rouge.png').readAsBytesSync());
    // Rien en clair ne reste dans les temporaires.
    expect(Directory('${paths.secureTempDir.path}/export').listSync(), isEmpty);
  });
}
