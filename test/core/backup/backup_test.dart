import 'dart:io';

import 'package:docusafe/core/backup/backup_service.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/documents/open_document.dart';
import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/security/auth/pin_attempts.dart';
import 'package:docusafe/core/security/crypto/argon2_params.dart';
import 'package:docusafe/core/security/crypto/dart_crypto_engine.dart';
import 'package:docusafe/core/security/keys/recovery_key.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/lock/vault_session.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/core/storage/vault_paths.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sauvegarde chiffrée et restauration sur un autre téléphone (choix D13).
void main() {
  late Directory root;

  VaultService serviceFor(VaultPaths paths) {
    final store = InMemorySecureStore();
    return VaultService(
      crypto: const DartCryptoEngine(),
      store: store,
      biometricStore: null,
      paths: paths,
      attempts: PinAttempts(store),
      argon2Params: Argon2Params.testOnly,
    );
  }

  setUp(() async => root = await Directory.systemTemp.createTemp('backup_test'));
  tearDown(() => root.delete(recursive: true));

  test('sauvegarder, puis restaurer sur un autre téléphone', () async {
    // Téléphone A : un coffre avec un document.
    final pathsA = VaultPaths.under(Directory('${root.path}/a'));
    final serviceA = serviceFor(pathsA);
    final pending = await serviceA.prepareSetup('204915');
    final recoveryKey = RecoveryKey.parse(pending.recoveryKey.display);
    final sessionA = await serviceA.commitSetup(pending);
    await pathsA.secureTempDir.create(recursive: true);
    final src = await File('test/fixtures/simple.pdf')
        .copy('${pathsA.secureTempDir.path}/bail.pdf');
    final ingest = IngestDocument(
      session: sessionA,
      paths: pathsA,
      thumbnails: const ImageOnlyThumbnailService(),
    );
    final check = await ingest.check(src) as FileAccepted;
    await ingest(IngestRequest(
      source: src,
      fileName: 'bail.pdf',
      check: check,
      title: 'Bail',
      categoryId: 'default-housing',
    ));

    final backupA = BackupService(paths: pathsA);
    final file = await backupA.create(sessionA, now: DateTime(2026, 11, 14, 10));
    // Rien en clair dans la sauvegarde.
    final raw = file.readAsBytesSync();
    final pdf = File('test/fixtures/simple.pdf').readAsBytesSync();
    expect(_contains(raw, pdf.sublist(0, 64)), isFalse);
    expect(_contains(raw, 'Bail'.codeUnits), isFalse);
    final copy = await file.copy('${root.path}/transfert.docusafe');
    await backupA.discard(file);
    expect(file.existsSync(), isFalse);
    await sessionA.close();

    // Téléphone B : vide, il reçoit le fichier.
    final pathsB = VaultPaths.under(Directory('${root.path}/b'));
    final serviceB = serviceFor(pathsB);
    final backupB = BackupService(paths: pathsB);
    final info = await backupB.unpack(copy);
    expect(info.documentCount, 1);
    expect(info.createdAt.toUtc(), DateTime(2026, 11, 14, 10).toUtc());

    final slot = await backupB.unpackedRecoverySlot();
    await expectLater(
      serviceB.unwrapRecoverySlot(slot, RecoveryKey.generate()),
      throwsA(isA<AuthException>()),
    );
    final vaultKey = await serviceB.unwrapRecoverySlot(slot, recoveryKey);
    final sessionB = await serviceB.restore(vaultKey: vaultKey, pin: '813572');
    expect(backupB.restoreDir.existsSync(), isFalse);
    final docs = await sessionB.database.documentsDao.getAll();
    expect(docs.single.title, 'Bail');
    final opened = await OpenDocument(session: sessionB, paths: pathsB)(docs.single);
    expect(await opened.readAll(), pdf);
    await opened.dispose();
    await sessionB.close();

    // Le nouveau code ouvre le coffre restauré ; la clé de récupération aussi.
    final again = await serviceB.unlockWithPin('813572');
    await again.close();
    final byKey = await serviceB.unlockWithRecoveryKey(recoveryKey);
    await byKey.close();
  });

  test('fichier abîmé ou étranger : refusé sans toucher au coffre', () async {
    final paths = VaultPaths.under(Directory('${root.path}/a'));
    final service = serviceFor(paths);
    final VaultSession session =
        await service.commitSetup(await service.prepareSetup('204915'));
    final backup = BackupService(paths: paths);
    final file = await backup.create(session, now: DateTime(2026, 11, 14));

    final damaged = File('${root.path}/abime.docusafe')
      ..writeAsBytesSync(file.readAsBytesSync());
    final bytes = damaged.readAsBytesSync();
    bytes[bytes.length ~/ 3] ^= 0xFF;
    damaged.writeAsBytesSync(bytes);
    await expectLater(backup.unpack(damaged), throwsA(isA<ValidationException>()));
    expect(backup.restoreDir.existsSync(), isFalse);

    final foreign = File('${root.path}/photo.docusafe')
      ..writeAsBytesSync(File('test/fixtures/rouge.png').readAsBytesSync());
    await expectLater(backup.unpack(foreign), throwsA(isA<ValidationException>()));

    // Le coffre d'origine est intact.
    expect(await session.database.documentsDao.getAll(), isEmpty);
    await backup.discard(file);
    await session.close();
  });
}

bool _contains(List<int> haystack, List<int> needle) {
  outer:
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        continue outer;
      }
    }
    return true;
  }
  return false;
}
