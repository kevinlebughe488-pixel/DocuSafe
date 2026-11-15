import 'dart:io';

import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/documents/open_document.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/security/auth/pin_attempts.dart';
import 'package:docusafe/core/security/crypto/argon2_params.dart';
import 'package:docusafe/core/security/crypto/dart_crypto_engine.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/core/storage/vault_paths.dart';
import 'package:flutter_test/flutter_test.dart';

/// Interruption d'une opération (cahier des charges §10) : au déverrouillage
/// suivant, les fichiers provisoires et les fichiers orphelins disparaissent,
/// les documents enregistrés restent intacts.
void main() {
  late Directory root;
  late VaultPaths paths;
  late VaultService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('consistency_test');
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
  });

  tearDown(() => root.delete(recursive: true));

  test('déverrouillage : provisoires et orphelins supprimés, documents intacts', () async {
    var session = await service.commitSetup(await service.prepareSetup('204915'));
    await paths.secureTempDir.create(recursive: true);
    final source = await File('test/fixtures/rouge.png')
        .copy('${paths.secureTempDir.path}/photo.png');
    final ingest = IngestDocument(
      session: session,
      paths: paths,
      thumbnails: const ImageOnlyThumbnailService(),
    );
    final check = await ingest.check(source) as FileAccepted;
    final row = await ingest(IngestRequest(
      source: source,
      fileName: 'photo.png',
      check: check,
      title: 'Photo',
      categoryId: 'default-identity',
    ));
    final document = paths.fileFor(row.encryptedFilePath);
    final thumbnail = paths.fileFor(VaultPaths.thumbnailRelativePath(row.id));
    expect(document.existsSync(), isTrue);
    expect(thumbnail.existsSync(), isTrue);
    await session.close();

    // Traces d'opérations interrompues : enregistrement coupé avant le
    // renommage (.part), enregistrement coupé avant l'écriture en base et
    // suppression coupée après la base (fichiers sans document).
    final partial = File('${document.parent.path}/coupe.dsf.part')
      ..writeAsBytesSync([1, 2, 3]);
    final orphan = File('${paths.filesDir.path}/zz/orphelin.dsf')
      ..createSync(recursive: true)
      ..writeAsBytesSync([4, 5, 6]);
    final orphanThumb = File('${paths.thumbsDir.path}/zz/orphelin.dst')
      ..createSync(recursive: true)
      ..writeAsBytesSync([7, 8, 9]);
    final plain = File('${paths.secureTempDir.path}/clair.pdf')
      ..createSync(recursive: true)
      ..writeAsBytesSync([10]);

    session = await service.unlockWithPin('204915');
    expect(partial.existsSync(), isFalse);
    expect(orphan.existsSync(), isFalse);
    expect(orphanThumb.existsSync(), isFalse);
    expect(plain.existsSync(), isFalse);

    // Le document enregistré et sa miniature n'ont pas bougé.
    expect(document.existsSync(), isTrue);
    expect(thumbnail.existsSync(), isTrue);
    final open = OpenDocument(session: session, paths: paths);
    final opened = await open(row);
    expect(
      await opened.readAll(),
      File('test/fixtures/rouge.png').readAsBytesSync(),
    );
    expect(await open.thumbnail(row), isNotNull);
    await opened.dispose();
    await session.close();
  });
}
