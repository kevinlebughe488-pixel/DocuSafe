import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../errors/app_exception.dart';
import '../security/crypto/crypto_worker.dart';
import '../security/crypto/dart_crypto_engine.dart';
import '../security/crypto/file_cipher.dart';
import '../security/lock/vault_session.dart';
import '../storage/vault_paths.dart';
import '../utils/app_log.dart';
import '../utils/bytes.dart';
import '../utils/secure_random.dart';
import 'file_formats.dart';

/// Limites des sorties du coffre.
abstract final class ExportLimits {
  /// Délai avant la suppression d'un fichier partagé : l'application qui le
  /// reçoit doit avoir le temps de le lire (docs/04-securite.md §13).
  static const Duration sharedFileLifetime = Duration(minutes: 10);

  /// Taille maximale de l'archive « Exporter mes données ». L'enregistrement
  /// passe par la mémoire (sélecteur « Enregistrer sous » du système).
  static const int maxArchiveBytes = 200 * 1000 * 1000;
}

/// Fichier en clair prêt à sortir du coffre.
final class ExportedFile {
  const ExportedFile({
    required this.fileName,
    required this.mimeType,
    this.file,
    this.bytes,
  });

  /// Nom proposé : titre du document, extension d'origine.
  final String fileName;
  final String mimeType;

  /// Copie temporaire (partage). Supprimée automatiquement.
  final File? file;

  /// Contenu en mémoire (export). À effacer avec [wipe] après usage.
  final Uint8List? bytes;

  void wipe() => Bytes.wipe(bytes);
}

/// Sorties volontaires du coffre : partage, export d'un document, export de
/// toutes les données (docs/04-securite.md §13).
///
/// Chaque sortie déchiffre puis contrôle l'empreinte SHA-256 enregistrée :
/// un fichier altéré ne sort jamais. Les copies temporaires sont placées
/// dans `secure_tmp/`, purgé au verrouillage et au démarrage.
final class DocumentExporter {
  DocumentExporter({required this._session, required this._paths});

  final VaultSession _session;
  final VaultPaths _paths;

  static final Map<String, Timer> _pendingDeletes = {};

  /// Déchiffre [document] dans un fichier temporaire pour la feuille de
  /// partage. Le fichier est supprimé après [ExportLimits.sharedFileLifetime].
  Future<ExportedFile> prepareForSharing(DocumentRow document) async {
    final source = _encryptedFile(document);
    final dir = Directory(
      p.join(_paths.secureTempDir.path, 'share', SecureRandom.uuid()),
    );
    await dir.create(recursive: true);
    final name = exportFileName(document);
    final temp = File(p.join(dir.path, name));
    try {
      final result = await CryptoWorker.decryptFile(
        source: source,
        destination: temp,
        rootKey: _session.filesRootKey,
      );
      if (result.sha256Hex != document.integrityHash) {
        throw CryptoException.integrity;
      }
    } on Object {
      await _deleteQuietly(dir);
      rethrow;
    }
    _scheduleDelete(dir);
    AppLog.event('document.shared');
    return ExportedFile(
      fileName: name,
      mimeType: document.fileType.format.mimeType,
      file: temp,
    );
  }

  /// Déchiffre [document] en mémoire pour l'enregistrer à l'emplacement
  /// choisi, sans fichier intermédiaire.
  Future<ExportedFile> decryptForExport(DocumentRow document) async {
    final (bytes, result) = await CryptoWorker.decryptFileToMemory(
      source: _encryptedFile(document),
      rootKey: _session.filesRootKey,
    );
    if (result.sha256Hex != document.integrityHash) {
      Bytes.wipe(bytes);
      throw CryptoException.integrity;
    }
    AppLog.event('document.exported');
    return ExportedFile(
      fileName: exportFileName(document),
      mimeType: document.fileType.format.mimeType,
      bytes: bytes,
    );
  }

  /// Archive ZIP de tous les documents, rangés par catégorie. Retourne
  /// `null` si le coffre est vide. Lève [StorageException]
  /// (`export.too_large`) au-delà de [ExportLimits.maxArchiveBytes].
  Future<ExportedFile?> buildArchive({
    required String uncategorizedFolder,
    required String archiveName,
  }) async {
    final db = _session.database;
    final documents = await db.documentsDao.getAll();
    if (documents.isEmpty) {
      return null;
    }
    final total = documents.fold<int>(0, (sum, d) => sum + d.fileSize);
    if (total > ExportLimits.maxArchiveBytes) {
      throw const StorageException('export.too_large');
    }
    final categories = {
      for (final c in await db.categoriesDao.getAll()) c.id: c.name,
    };
    final used = <String>{};
    final entries = <_ArchiveEntry>[
      for (final d in documents.reversed)
        _ArchiveEntry(
          source: _encryptedFile(d).path,
          name: _unique(
            used,
            p.posix.join(
              safeFileName(categories[d.categoryId] ?? uncategorizedFolder),
              exportFileName(d),
            ),
          ),
          integrityHash: d.integrityHash,
        ),
    ];

    final dir = Directory(
      p.join(_paths.secureTempDir.path, 'export', SecureRandom.uuid()),
    );
    await dir.create(recursive: true);
    final zipPath = p.join(dir.path, 'archive.zip');
    final key = Uint8List.fromList(_session.filesRootKey);
    try {
      await _runArchiveIsolate(entries, zipPath, dir.path, key);
      final bytes = await File(zipPath).readAsBytes();
      AppLog.event('vault.exported');
      return ExportedFile(
        fileName: archiveName,
        mimeType: 'application/zip',
        bytes: bytes,
      );
    } finally {
      Bytes.wipe(key);
      await _deleteQuietly(dir);
    }
  }

  File _encryptedFile(DocumentRow document) =>
      _paths.fileFor(document.encryptedFilePath);

  void _scheduleDelete(Directory dir) {
    _pendingDeletes[dir.path] = Timer(ExportLimits.sharedFileLifetime, () {
      _pendingDeletes.remove(dir.path);
      unawaited(_deleteQuietly(dir));
    });
  }

  /// Annule les suppressions différées (le verrouillage purge tout).
  static void cancelPendingDeletes() {
    for (final t in _pendingDeletes.values) {
      t.cancel();
    }
    _pendingDeletes.clear();
  }

  static Future<void> _deleteQuietly(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } on FileSystemException catch (e, s) {
      AppLog.error('export.temp_delete', e, s);
    }
  }

  /// Nom de fichier proposé : titre nettoyé et extension d'origine.
  static String exportFileName(DocumentRow document) {
    final ext = document.fileType.format.defaultExtension;
    final base = safeFileName(document.title);
    return '$base.$ext';
  }

  /// Retire les caractères interdits dans un nom de fichier (Android,
  /// iPhone, Windows) et limite la longueur.
  static String safeFileName(String raw) {
    var name = raw
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    while (name.startsWith('.')) {
      name = name.substring(1);
    }
    if (name.length > 80) {
      name = name.substring(0, 80).trimRight();
    }
    return name.isEmpty ? 'document' : name;
  }

  static String _unique(Set<String> used, String path) {
    var candidate = path;
    var n = 2;
    final ext = p.posix.extension(path);
    final stem = path.substring(0, path.length - ext.length);
    while (!used.add(candidate.toLowerCase())) {
      candidate = '$stem ($n)$ext';
      n++;
    }
    return candidate;
  }
}

final class _ArchiveEntry {
  const _ArchiveEntry({
    required this.source,
    required this.name,
    required this.integrityHash,
  });

  final String source;
  final String name;
  final String integrityHash;
}

/// Fonction de premier niveau : la fermeture envoyée à l'isolate ne capture
/// que des valeurs transmissibles (jamais la session ni la base).
Future<void> _runArchiveIsolate(
  List<_ArchiveEntry> entries,
  String zipPath,
  String workDir,
  Uint8List rootKey,
) => Isolate.run(
  () => _writeArchive(entries, zipPath, workDir, rootKey),
  debugName: 'exportArchive',
);

/// Exécuté dans un isolate : déchiffre chaque document dans [workDir],
/// contrôle son empreinte, l'ajoute à l'archive puis supprime le clair.
Future<void> _writeArchive(
  List<_ArchiveEntry> entries,
  String zipPath,
  String workDir,
  Uint8List rootKey,
) async {
  final cipher = FileCipher(const DartCryptoEngine());
  final encoder = ZipFileEncoder()
    ..create(zipPath, level: ZipFileEncoder.store);
  try {
    for (final entry in entries) {
      final plain = File(p.join(workDir, 'doc.tmp'));
      final result = await cipher.decryptFile(
        source: File(entry.source),
        destination: plain,
        rootKey: rootKey,
      );
      if (result.sha256Hex != entry.integrityHash) {
        await plain.delete();
        throw CryptoException.integrity;
      }
      await encoder.addFile(plain, entry.name, ZipFileEncoder.store);
      await plain.delete();
    }
  } finally {
    await encoder.close();
  }
}
