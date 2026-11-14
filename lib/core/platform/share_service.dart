import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../errors/app_exception.dart';
import '../utils/app_log.dart';

/// Sorties volontaires du coffre : feuille de partage du système et
/// enregistrement d'une copie à l'emplacement choisi par l'utilisateur
/// (docs/04-securite.md §13).
abstract interface class ShareService {
  /// Ouvre la feuille de partage du système avec [file]. Retourne `false`
  /// si l'utilisateur a fermé la feuille sans partager.
  Future<bool> shareFile(File file, {required String mimeType});

  /// Ouvre le sélecteur « Enregistrer sous » du système et y écrit [bytes].
  /// Retourne `false` si l'utilisateur annule.
  Future<bool> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  });
}

final class PlatformShareService implements ShareService {
  const PlatformShareService();

  @override
  Future<bool> shareFile(File file, {required String mimeType}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: mimeType)]),
      );
      return result.status != ShareResultStatus.dismissed;
    } on Exception catch (e, s) {
      AppLog.error('share.sheet', e, s);
      throw StorageException('share.sheet', cause: e);
    }
  }

  @override
  Future<bool> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      return uri != null;
    } on Exception catch (e, s) {
      AppLog.error('share.save', e, s);
      throw StorageException('share.save', cause: e);
    }
  }
}

/// Version simulée pour les tests : garde la trace de ce qui est sorti.
final class FakeShareService implements ShareService {
  /// Contenu lu au moment du partage (le fichier est supprimé plus tard).
  final List<(String name, Uint8List bytes)> shared = [];
  final List<(String name, Uint8List bytes)> saved = [];

  /// `false` : l'utilisateur annule le sélecteur ou la feuille.
  bool accept = true;

  @override
  Future<bool> shareFile(File file, {required String mimeType}) async {
    shared.add((file.uri.pathSegments.last, await file.readAsBytes()));
    return accept;
  }

  @override
  Future<bool> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (accept) {
      saved.add((fileName, Uint8List.fromList(bytes)));
    }
    return accept;
  }
}
