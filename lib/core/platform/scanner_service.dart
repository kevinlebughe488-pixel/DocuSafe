import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';

import '../errors/app_exception.dart';
import '../utils/app_log.dart';

/// Scanner de documents du système (docs/01-analyse.md, D4) : ML Kit sur
/// Android, VisionKit sur iOS (à vérifier sur iOS), avec repli à recadrage
/// manuel sur les téléphones sans services Google Play. Détection des
/// contours, correction de perspective, recadrage, filtres et plusieurs
/// pages sont fournis par l'écran du système.
abstract interface class ScannerService {
  /// Ouvre le scanner. Retourne les pages (images) dans l'ordre, ou une
  /// liste vide si l'utilisateur annule.
  Future<List<File>> scan();

  /// Supprime les images laissées par le scanner (docs/04-securite.md §12).
  Future<void> cleanCache();
}

final class PlatformScannerService implements ScannerService {
  const PlatformScannerService();

  @override
  Future<List<File>> scan() async {
    try {
      final result = await CunningDocumentScanner.scanDocuments();
      if (result == null) {
        return const [];
      }
      return [for (final path in result.images) File(path)];
    } on CunningDocumentScannerException catch (e, s) {
      AppLog.error('scanner.failed', e, s);
      throw ScannerException(cameraDenied: e.code == 'permission_denied');
    } on PlatformException catch (e, s) {
      AppLog.error('scanner.platform', e, s);
      throw const ScannerException();
    }
  }

  @override
  Future<void> cleanCache() async {
    try {
      await CunningDocumentScanner.cleanCache();
    } on Object catch (e, s) {
      AppLog.error('scanner.clean', e, s);
    }
  }
}

/// Scanner simulé : retourne des images préparées (tests).
final class FakeScannerService implements ScannerService {
  FakeScannerService({this.pages = const [], this.error});

  /// Pages rendues au prochain appel de [scan].
  List<File> pages;

  /// Erreur levée par [scan] à la place des pages (scanner indisponible).
  AppException? error;
  int scanCalls = 0;
  int cleanCalls = 0;

  @override
  Future<List<File>> scan() async {
    scanCalls++;
    if (error case final AppException e) {
      throw e;
    }
    return pages;
  }

  @override
  Future<void> cleanCache() async => cleanCalls++;
}
