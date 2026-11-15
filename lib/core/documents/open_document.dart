import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../errors/app_exception.dart';
import '../security/crypto/crypto_worker.dart';
import '../security/lock/vault_session.dart';
import '../storage/vault_paths.dart';
import '../utils/app_log.dart';
import '../utils/bytes.dart';
import '../utils/secure_random.dart';

/// Document déchiffré, prêt à être affiché. En mémoire jusqu'à 20 Mo,
/// sinon dans un fichier temporaire privé supprimé par [dispose]
/// (docs/04-securite.md §12).
final class OpenedDocument {
  OpenedDocument._({required this.document, this.bytes, this.tempFile});

  final DocumentRow document;
  final Uint8List? bytes;
  final File? tempFile;

  DocumentFileType get type => document.fileType;

  /// Contenu en clair, lu depuis la mémoire ou le fichier temporaire.
  Future<Uint8List> readAll() async =>
      bytes ?? await tempFile!.readAsBytes();

  /// Efface le clair : écrase les octets en mémoire, supprime le fichier.
  Future<void> dispose() async {
    Bytes.wipe(bytes);
    final f = tempFile;
    if (f != null && await f.exists()) {
      try {
        await f.delete();
      } on FileSystemException catch (e, s) {
        AppLog.error('document.temp_delete', e, s);
      }
    }
  }
}

/// Cas d'utilisation `OpenDocument` : déchiffrement, contrôle d'intégrité
/// (sceaux de chaque bloc **et** empreinte SHA-256 enregistrée en base),
/// puis mise à jour de « consulté récemment ».
///
/// Lève [CryptoException.integrity] si le fichier a été modifié, tronqué ou
/// remplacé ; [StorageException] s'il a disparu. Rien n'est affiché alors.
final class OpenDocument {
  OpenDocument({
    required this._session,
    required this._paths,
  });

  final VaultSession _session;
  final VaultPaths _paths;

  Future<OpenedDocument> call(DocumentRow document) async {
    final encrypted = _paths.fileFor(document.encryptedFilePath);
    if (!await encrypted.exists()) {
      throw const StorageException('document.missing');
    }
    final OpenedDocument opened;
    if (document.fileSize <= DocumentLimits.maxInMemoryBytes) {
      final (bytes, result) = await CryptoWorker.decryptFileToMemory(
        source: encrypted,
        rootKey: _session.filesRootKey,
      );
      if (result.sha256Hex != document.integrityHash) {
        Bytes.wipe(bytes);
        throw CryptoException.integrity;
      }
      opened = OpenedDocument._(document: document, bytes: bytes);
    } else {
      await _paths.secureTempDir.create(recursive: true);
      final temp = File(
        p.join(
          _paths.secureTempDir.path,
          '${SecureRandom.uuid()}.${document.fileType.name}',
        ),
      );
      final result = await CryptoWorker.decryptFile(
        source: encrypted,
        destination: temp,
        rootKey: _session.filesRootKey,
      );
      if (result.sha256Hex != document.integrityHash) {
        if (await temp.exists()) {
          await temp.delete();
        }
        throw CryptoException.integrity;
      }
      opened = OpenedDocument._(document: document, tempFile: temp);
    }
    await _session.database.documentsDao.markOpened(document.id);
    AppLog.event('document.opened');
    return opened;
  }

  /// Miniature déchiffrée (JPEG), ou `null` s'il n'y en a pas ou si elle
  /// est altérée.
  Future<Uint8List?> thumbnail(DocumentRow document) async {
    final file = _paths.fileFor(VaultPaths.thumbnailRelativePath(document.id));
    if (!await file.exists()) {
      return null;
    }
    try {
      final (bytes, _) = await CryptoWorker.decryptFileToMemory(
        source: file,
        rootKey: _session.thumbnailsRootKey,
      );
      return bytes;
    } on CryptoException catch (e, s) {
      AppLog.error('thumbnail.integrity', e, s);
      return null;
    }
  }
}
