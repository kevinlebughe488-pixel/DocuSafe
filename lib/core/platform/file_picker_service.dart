import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../documents/file_formats.dart';
import '../errors/app_exception.dart';
import '../utils/app_log.dart';

/// Fichier choisi par l'utilisateur, avant toute vérification.
final class PickedFile {
  const PickedFile({required this.file, required this.displayName});

  /// Copie locale lisible (le sélecteur la place dans le cache privé).
  final File file;

  /// Nom d'origine, affiché et proposé comme titre.
  final String displayName;
}

/// Sélecteurs du système : fichiers (PDF, images) et galerie (photos).
///
/// Les sélecteurs donnent accès au seul fichier choisi : aucune permission
/// de stockage n'est demandée (docs/04-securite.md §16).
abstract interface class FilePickerService {
  /// Sélecteur de fichiers, plusieurs fichiers possibles. Liste vide si
  /// l'utilisateur annule.
  Future<List<PickedFile>> pickDocuments();

  /// Galerie photos, plusieurs images possibles.
  Future<List<PickedFile>> pickPhotos();

  /// Un fichier de sauvegarde DocSafe (n'importe quel type : l'extension
  /// `.docsafe` n'est pas connue du système). `null` si annulé.
  Future<PickedFile?> pickBackup();

  /// Nettoie les copies temporaires créées par les sélecteurs.
  Future<void> clearTemporaryFiles();
}

final class PlatformFilePickerService implements FilePickerService {
  PlatformFilePickerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<List<PickedFile>> pickDocuments() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: FileFormats.pickerExtensions,
      );
      return [
        for (final f in files)
          if (f.path != null)
            PickedFile(file: File(f.path!), displayName: f.name),
      ];
    } on Exception catch (e, s) {
      AppLog.error('picker.documents', e, s);
      throw StorageException('picker.documents', cause: e);
    }
  }

  @override
  Future<List<PickedFile>> pickPhotos() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        requestFullMetadata: false,
      );
      return [
        for (final x in images)
          PickedFile(file: File(x.path), displayName: x.name),
      ];
    } on Exception catch (e, s) {
      AppLog.error('picker.photos', e, s);
      throw StorageException('picker.photos', cause: e);
    }
  }

  @override
  Future<PickedFile?> pickBackup() async {
    try {
      final files = await FilePicker.pickFiles();
      final f = files.isEmpty ? null : files.first;
      if (f == null || f.path == null) {
        return null;
      }
      return PickedFile(file: File(f.path!), displayName: f.name);
    } on Exception catch (e, s) {
      AppLog.error('picker.backup', e, s);
      throw StorageException('picker.backup', cause: e);
    }
  }

  @override
  Future<void> clearTemporaryFiles() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } on Exception catch (e, s) {
      AppLog.error('picker.clear', e, s);
    }
  }
}

/// Sélecteur simulé : retourne des fichiers préparés (tests).
final class FakeFilePickerService implements FilePickerService {
  FakeFilePickerService({
    this.documents = const [],
    this.photos = const [],
    this.backup,
  });

  List<PickedFile> documents;
  List<PickedFile> photos;
  PickedFile? backup;
  int clearCalls = 0;

  @override
  Future<List<PickedFile>> pickDocuments() async => documents;

  @override
  Future<List<PickedFile>> pickPhotos() async => photos;

  @override
  Future<PickedFile?> pickBackup() async => backup;

  @override
  Future<void> clearTemporaryFiles() async => clearCalls++;
}
