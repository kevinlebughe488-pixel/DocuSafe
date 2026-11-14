import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../errors/app_exception.dart';
import '../platform/thumbnail_service.dart';
import '../security/crypto/crypto_worker.dart';
import '../security/lock/vault_session.dart';
import '../storage/vault_paths.dart';
import '../utils/app_log.dart';
import '../utils/bytes.dart';
import '../utils/date_only.dart';
import '../utils/secure_random.dart';
import 'file_formats.dart';

/// Résultat de la vérification d'un fichier avant importation
/// (docs/05-parcours-utilisateurs.md §4).
sealed class FileCheck {
  const FileCheck();
}

/// Fichier accepté.
final class FileAccepted extends FileCheck {
  const FileAccepted({
    required this.format,
    required this.size,
    required this.sha256Hex,
    required this.preview,
    this.duplicateOf,
  });

  final FileFormat format;
  final int size;
  final String sha256Hex;
  final FilePreview preview;

  /// Document déjà présent avec la même empreinte, s'il existe.
  final DocumentRow? duplicateOf;

  bool get isDuplicate => duplicateOf != null;
}

/// Fichier refusé, avec la raison.
final class FileRejected extends FileCheck {
  const FileRejected(this.reason);

  final FileRejectReason reason;
}

enum FileRejectReason { unsupportedFormat, tooLarge, unreadable, empty }

/// Informations saisies pour un document à enregistrer.
final class IngestRequest {
  const IngestRequest({
    required this.source,
    required this.fileName,
    required this.check,
    required this.title,
    required this.categoryId,
    this.docType,
    this.description,
    this.issueDate,
    this.expirationDate,
    this.tags = const [],
    this.deleteSource = true,
  });

  /// Fichier en clair (copie temporaire privée).
  final File source;

  /// Nom du fichier d'origine, conservé pour l'export.
  final String fileName;
  final FileAccepted check;
  final String title;
  final String categoryId;
  final String? docType;
  final String? description;
  final DateOnly? issueDate;
  final DateOnly? expirationDate;
  final List<String> tags;

  /// Supprimer le fichier en clair une fois le document enregistré.
  final bool deleteSource;
}

/// Étapes de l'enregistrement, pour la progression affichée.
enum IngestStage { encrypting, verifying, thumbnail, saving, cleaning }

/// Cas d'utilisation `IngestDocument` (docs/02-architecture.md §7) : chemin
/// unique pour le scanner, l'importation et le partage entrant.
///
/// 1. [check] : type réel, taille, lisibilité, doublon.
/// 2. [call] : chiffrement sous un nom provisoire → relecture de contrôle →
///    miniature chiffrée → enregistrement en base (une transaction) →
///    suppression des fichiers en clair.
///
/// Si l'application est interrompue, un document n'apparaît jamais à moitié
/// enregistré : le renommage du fichier chiffré est une opération unique et
/// la ligne en base n'est écrite qu'après.
final class IngestDocument {
  IngestDocument({
    required this._session,
    required this._paths,
    required this._thumbnails,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final VaultSession _session;
  final VaultPaths _paths;
  final ThumbnailService _thumbnails;
  final DateTime Function() _clock;

  AppDatabase get _db => _session.database;

  /// Vérifie un fichier : type réel (signature), taille, lisibilité,
  /// empreinte et doublon. Ne modifie rien.
  Future<FileCheck> check(File source) async {
    final int size;
    try {
      if (!await source.exists()) {
        return const FileRejected(FileRejectReason.unreadable);
      }
      size = await source.length();
    } on FileSystemException {
      return const FileRejected(FileRejectReason.unreadable);
    }
    if (size == 0) {
      return const FileRejected(FileRejectReason.empty);
    }
    if (size > DocumentLimits.maxFileSizeBytes) {
      return const FileRejected(FileRejectReason.tooLarge);
    }
    final FileFormat? format;
    try {
      format = await FileFormats.detectFile(source);
    } on FileSystemException {
      return const FileRejected(FileRejectReason.unreadable);
    }
    if (format == null) {
      return const FileRejected(FileRejectReason.unsupportedFormat);
    }
    final hash = await _sha256Of(source);
    final preview = await _thumbnails.preview(source, format.type);
    if (format.type == DocumentFileType.pdf && preview.pageCount == 0) {
      return const FileRejected(FileRejectReason.unreadable);
    }
    return FileAccepted(
      format: format,
      size: size,
      sha256Hex: hash,
      preview: preview,
      duplicateOf: await _db.documentsDao.findByHash(hash),
    );
  }

  /// Enregistre le document dans le coffre et retourne sa ligne.
  Future<DocumentRow> call(
    IngestRequest request, {
    void Function(IngestStage stage)? onStage,
  }) async {
    final title = request.title.trim();
    if (title.isEmpty || title.length > DocumentLimits.maxTitleLength) {
      throw const ValidationException('validation.title');
    }
    final id = SecureRandom.uuid();
    final relativePath = VaultPaths.documentRelativePath(id);
    final thumbRelativePath = VaultPaths.thumbnailRelativePath(id);
    final encrypted = _paths.fileFor(relativePath);
    final partial = File('${encrypted.path}.part');
    final thumbFile = _paths.fileFor(thumbRelativePath);
    await encrypted.parent.create(recursive: true);
    await thumbFile.parent.create(recursive: true);

    try {
      // 1. Chiffrement par blocs vers un fichier provisoire.
      onStage?.call(IngestStage.encrypting);
      final result = await CryptoWorker.encryptFile(
        source: request.source,
        destination: partial,
        rootKey: _session.filesRootKey,
      );
      if (result.sha256Hex != request.check.sha256Hex) {
        // Le fichier a changé entre la vérification et l'enregistrement.
        throw CryptoException.integrity;
      }

      // 2. Relecture de contrôle : le fichier chiffré se déchiffre et donne
      //    la même empreinte.
      onStage?.call(IngestStage.verifying);
      final verified = await CryptoWorker.verifyFile(
        source: partial,
        rootKey: _session.filesRootKey,
      );
      if (!Bytes.constantTimeEquals(verified.sha256, result.sha256)) {
        throw CryptoException.integrity;
      }

      // 3. Miniature chiffrée (facultative : un document sans miniature
      //    reste valide).
      onStage?.call(IngestStage.thumbnail);
      final thumbnail = request.check.preview.thumbnailJpeg;
      if (thumbnail != null) {
        final sealed = await CryptoWorker.encryptBytes(
          plaintext: thumbnail,
          rootKey: _session.thumbnailsRootKey,
        );
        await thumbFile.writeAsBytes(sealed, flush: true);
      }

      // 4. Renommage unique, puis enregistrement en base.
      onStage?.call(IngestStage.saving);
      await partial.rename(encrypted.path);
      final now = _clock();
      final companion = DocumentsCompanion.insert(
        id: id,
        title: title,
        docType: Value(_clean(request.docType)),
        categoryId: request.categoryId,
        fileName: request.fileName,
        encryptedFilePath: relativePath,
        fileType: request.check.format.type,
        fileSize: request.check.size,
        pageCount: Value(request.check.preview.pageCount),
        createdAt: now,
        updatedAt: now,
        issueDate: Value(request.issueDate),
        expirationDate: Value(request.expirationDate),
        description: Value(_clean(request.description)),
        integrityHash: result.sha256Hex,
      );
      try {
        await _db.documentsDao.insertDocument(companion, tagNames: request.tags);
      } on Object {
        await _deleteQuietly(encrypted);
        await _deleteQuietly(thumbFile);
        rethrow;
      }

      // 5. Suppression du fichier en clair.
      onStage?.call(IngestStage.cleaning);
      if (request.deleteSource) {
        await _deleteQuietly(request.source);
      }
      AppLog.event('document.ingested');
      return (await _db.documentsDao.getById(id))!;
    } on Object {
      await _deleteQuietly(partial);
      await _deleteQuietly(thumbFile);
      rethrow;
    }
  }

  static String? _clean(String? value) {
    final v = value?.trim();
    return v == null || v.isEmpty ? null : v;
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (e, s) {
      AppLog.error('file.delete', e, s);
    }
  }

  static Future<String> _sha256Of(File file) async {
    final digest = await crypto.sha256.bind(file.openRead()).first;
    return Bytes.toHex(Uint8List.fromList(digest.bytes));
  }
}
