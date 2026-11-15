import 'dart:io';

import '../database/app_database.dart';
import '../security/lock/vault_session.dart';
import '../storage/vault_paths.dart';
import '../utils/app_log.dart';

/// Cas d'utilisation `DeleteDocument` (docs/03-modele-de-donnees.md §3) :
/// 1. transaction en base (document, tags, rappels, index) ;
/// 2. suppression du fichier chiffré et de la miniature.
///
/// Si l'étape 2 échoue, le document a déjà disparu pour l'utilisateur et le
/// fichier orphelin sera supprimé par le contrôle de cohérence.
final class DeleteDocument {
  DeleteDocument({
    required this._session,
    required this._paths,
  });

  final VaultSession _session;
  final VaultPaths _paths;

  Future<void> call(DocumentRow document) async {
    await _session.database.documentsDao.deleteDocument(document.id);
    for (final file in [
      _paths.fileFor(document.encryptedFilePath),
      _paths.fileFor(VaultPaths.thumbnailRelativePath(document.id)),
    ]) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException catch (e, s) {
        AppLog.error('document.file_delete', e, s);
      }
    }
    AppLog.event('document.deleted');
  }
}
