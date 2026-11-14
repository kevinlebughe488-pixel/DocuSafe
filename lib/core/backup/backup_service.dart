import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../security/lock/vault_session.dart';
import '../storage/vault_paths.dart';
import '../utils/app_log.dart';
import '../utils/secure_random.dart';

/// Résumé d'une sauvegarde, lu dans son manifeste.
final class BackupInfo {
  const BackupInfo({
    required this.createdAt,
    required this.documentCount,
    required this.totalBytes,
  });

  final DateTime createdAt;
  final int documentCount;

  /// Taille des documents en clair (indicative).
  final int totalBytes;
}

/// Sauvegarde chiffrée manuelle (choix D13, docs/04-securite.md §13 bis).
///
/// Format `DSB1` : une archive ZIP sans compression qui contient le coffre
/// **tel qu'il est stocké**, donc déjà chiffré :
/// - `docusafe.db` : la base chiffrée (SQLite3MultipleCiphers) ;
/// - `files/…` et `thumbs/…` : documents et miniatures chiffrés (DSF1) ;
/// - `recovery.slot` : la clé du coffre, enfermée par la clé de récupération ;
/// - `manifest.json` : format, date, nombre de documents, empreinte SHA-256
///   de chaque fichier (aucun titre, aucun nom de document).
///
/// Rien n'est déchiffré pour sauvegarder. Pour restaurer, il faut la clé de
/// récupération en vigueur au moment de la sauvegarde.
final class BackupService {
  BackupService({required this._paths});

  final VaultPaths _paths;

  static const String format = 'DSB1';
  static const String fileExtension = 'docusafe';
  static const String mimeType = 'application/octet-stream';
  static const String manifestName = 'manifest.json';

  /// Prépare le fichier de sauvegarde dans un dossier temporaire et le
  /// retourne. À supprimer après l'enregistrement ([discard]).
  Future<File> create(VaultSession session, {required DateTime now}) async {
    final db = session.database;
    final staging = Directory(
      p.join(_paths.secureTempDir.path, 'backup', SecureRandom.uuid()),
    );
    await staging.create(recursive: true);
    try {
      // Copie cohérente de la base : la lecture ouvre une transaction qui
      // empêche toute écriture pendant la copie.
      final dbCopy = File(p.join(staging.path, AppConfig.databaseFileName));
      late int count;
      late int total;
      await db.transaction(() async {
        final docs = await db.documentsDao.getAll();
        count = docs.length;
        total = docs.fold<int>(0, (sum, d) => sum + d.fileSize);
        await _paths.databaseFile.copy(dbCopy.path);
      });

      final entries = <(String, String)>[
        (dbCopy.path, AppConfig.databaseFileName),
        (_paths.recoverySlotFile.path, AppConfig.recoverySlotFileName),
        for (final dir in [_paths.filesDir, _paths.thumbsDir])
          if (await dir.exists())
            await for (final f in dir.list(recursive: true))
              if (f is File && !f.path.endsWith('.part'))
                (f.path, p.relative(f.path, from: _paths.vaultDir.path)
                    .replaceAll(r'\', '/')),
      ];
      final output = p.join(staging.path, 'sauvegarde.$fileExtension');
      final header = {
        'format': format,
        'version': 1,
        'createdAt': now.toUtc().toIso8601String(),
        'documentCount': count,
        'totalBytes': total,
      };
      await _runBackupIsolate(entries, header, output);
      AppLog.event('backup.created');
      return File(output);
    } on Object {
      await _deleteQuietly(staging);
      rethrow;
    }
  }

  /// Supprime le dossier temporaire d'une sauvegarde créée par [create].
  Future<void> discard(File backup) => _deleteQuietly(backup.parent);

  /// Dossier où une sauvegarde est décompressée avant d'être restaurée.
  Directory get restoreDir => _paths.restoreDir;

  /// Décompresse [backup] dans [restoreDir] et contrôle chaque fichier.
  ///
  /// Lève [ValidationException] (`backup.invalid`) si ce n'est pas une
  /// sauvegarde DocuSafe ou si un fichier est abîmé. Rien n'est modifié dans
  /// le coffre actuel.
  Future<BackupInfo> unpack(File backup) async {
    final dir = restoreDir;
    await _deleteQuietly(dir);
    await dir.create(recursive: true);
    try {
      final header = await _runUnpackIsolate(backup.path, dir.path);
      return BackupInfo(
        createdAt: DateTime.parse(header['createdAt'] as String).toLocal(),
        documentCount: header['documentCount'] as int,
        totalBytes: header['totalBytes'] as int,
      );
    } on ValidationException {
      await _deleteQuietly(dir);
      rethrow;
    } on Object catch (e, s) {
      AppLog.error('backup.unpack', e, s);
      await _deleteQuietly(dir);
      throw const ValidationException('backup.invalid');
    }
  }

  /// Contenu de la serrure de récupération de la sauvegarde décompressée.
  Future<String> unpackedRecoverySlot() =>
      File(p.join(restoreDir.path, AppConfig.recoverySlotFileName))
          .readAsString();

  /// Abandonne une restauration en cours.
  Future<void> discardUnpacked() => _deleteQuietly(restoreDir);

  static Future<void> _deleteQuietly(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } on FileSystemException catch (e, s) {
      AppLog.error('backup.temp_delete', e, s);
    }
  }
}

// ---------------------------------------------------------------------------
// Travail dans un isolate
// ---------------------------------------------------------------------------

/// Fonctions de premier niveau : la fermeture envoyée à l'isolate ne capture
/// que des valeurs transmissibles (jamais la session ni la base).
Future<void> _runBackupIsolate(
  List<(String, String)> entries,
  Map<String, Object> header,
  String output,
) => Isolate.run(
  () => _writeBackup(entries, header, output),
  debugName: 'backup',
);

Future<Map<String, Object?>> _runUnpackIsolate(String backup, String dir) =>
    Isolate.run(() => _unpackAndVerify(backup, dir), debugName: 'restoreUnpack');

Future<String> _sha256Of(String path) async {
  final digest = await sha256.bind(File(path).openRead()).first;
  return digest.toString();
}

Future<void> _writeBackup(
  List<(String, String)> entries,
  Map<String, Object> header,
  String output,
) async {
  final hashes = <String, String>{
    for (final (path, name) in entries) name: await _sha256Of(path),
  };
  final encoder = ZipFileEncoder()
    ..create(output, level: ZipFileEncoder.store);
  try {
    for (final (path, name) in entries) {
      await encoder.addFile(File(path), name, ZipFileEncoder.store);
    }
    final manifest = jsonEncode({...header, 'files': hashes});
    encoder.addArchiveFile(
      ArchiveFile.string(BackupService.manifestName, manifest),
    );
  } finally {
    await encoder.close();
  }
}

/// Noms autorisés dans une sauvegarde : rien d'autre n'est accepté.
bool _allowedName(String name) {
  if (name.contains('..') || name.startsWith('/') || name.contains(r'\')) {
    return false;
  }
  return name == AppConfig.databaseFileName ||
      name == AppConfig.recoverySlotFileName ||
      name == BackupService.manifestName ||
      RegExp(r'^(files|thumbs)/[A-Za-z0-9._/-]+$').hasMatch(name);
}

Future<Map<String, Object?>> _unpackAndVerify(String backup, String dir) async {
  const invalid = ValidationException('backup.invalid');
  final input = InputFileStream(backup);
  try {
    final archive = ZipDecoder().decodeStream(input);
    for (final entry in archive) {
      if (entry.isFile && !_allowedName(entry.name)) {
        throw invalid;
      }
    }
    extractArchiveToDiskSync(archive, dir, throwOnError: true);
  } on ValidationException {
    rethrow;
  } on Object {
    throw invalid;
  } finally {
    input.closeSync();
  }

  final manifestFile = File(p.join(dir, BackupService.manifestName));
  if (!manifestFile.existsSync()) {
    throw invalid;
  }
  final Map<String, Object?> manifest;
  try {
    manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, Object?>;
  } on FormatException {
    throw invalid;
  }
  final files = manifest['files'];
  if (manifest['format'] != BackupService.format ||
      manifest['version'] != 1 ||
      manifest['createdAt'] is! String ||
      manifest['documentCount'] is! int ||
      manifest['totalBytes'] is! int ||
      files is! Map<String, Object?> ||
      !files.containsKey(AppConfig.databaseFileName) ||
      !files.containsKey(AppConfig.recoverySlotFileName)) {
    throw invalid;
  }
  // Chaque fichier annoncé est présent et intact ; aucun fichier en trop.
  final onDisk = <String>{
    for (final f in Directory(dir).listSync(recursive: true))
      if (f is File) p.relative(f.path, from: dir).replaceAll(r'\', '/'),
  }..remove(BackupService.manifestName);
  if (onDisk.length != files.length || !onDisk.containsAll(files.keys)) {
    throw invalid;
  }
  for (final MapEntry(:key, :value) in files.entries) {
    if (value is! String || await _sha256Of(p.join(dir, key)) != value) {
      throw invalid;
    }
  }
  manifestFile.deleteSync();
  return manifest;
}
