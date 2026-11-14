import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Emplacements des données sur le téléphone (docs/03-modele-de-donnees.md §6).
///
/// ```
/// <dossier privé>/vault/           base, serrure de récupération,
///                  files/ab/, thumbs/ab/
/// <cache privé>/secure_tmp/        fichiers temporaires en clair
/// ```
/// Tous les chemins enregistrés en base sont relatifs à [vaultDir].
final class VaultPaths {
  const VaultPaths({required this.vaultDir, required this.secureTempDir});

  /// Dossiers réels de l'application (path_provider).
  static Future<VaultPaths> resolve() async {
    final support = await getApplicationSupportDirectory();
    final cache = await getApplicationCacheDirectory();
    return VaultPaths(
      vaultDir: Directory(p.join(support.path, 'vault')),
      secureTempDir: Directory(p.join(cache.path, 'secure_tmp')),
    );
  }

  /// Dossiers dans un répertoire donné (tests).
  factory VaultPaths.under(Directory root) => VaultPaths(
    vaultDir: Directory(p.join(root.path, 'vault')),
    secureTempDir: Directory(p.join(root.path, 'secure_tmp')),
  );

  final Directory vaultDir;
  final Directory secureTempDir;

  File get databaseFile =>
      File(p.join(vaultDir.path, AppConfig.databaseFileName));
  File get recoverySlotFile =>
      File(p.join(vaultDir.path, AppConfig.recoverySlotFileName));
  Directory get filesDir => Directory(p.join(vaultDir.path, 'files'));
  Directory get thumbsDir => Directory(p.join(vaultDir.path, 'thumbs'));

  /// Sauvegarde décompressée en attente de restauration. À côté du coffre
  /// (même disque, pour un simple renommage) mais hors de lui : effacer le
  /// coffre ne l'efface pas.
  Directory get restoreDir =>
      Directory(p.join(p.dirname(vaultDir.path), 'vault_restore'));

  /// Chemin relatif du fichier chiffré d'un document.
  static String documentRelativePath(String id) =>
      p.join('files', id.substring(0, 2), '$id.dsf');

  /// Chemin relatif de la miniature chiffrée d'un document.
  static String thumbnailRelativePath(String id) =>
      p.join('thumbs', id.substring(0, 2), '$id.dst');

  File fileFor(String relativePath) => File(p.join(vaultDir.path, relativePath));

  /// Crée les dossiers s'ils manquent.
  Future<void> ensureCreated() async {
    await vaultDir.create(recursive: true);
    await filesDir.create(recursive: true);
    await thumbsDir.create(recursive: true);
    await secureTempDir.create(recursive: true);
  }

  /// Supprime tous les fichiers temporaires en clair.
  Future<void> purgeSecureTemp() async {
    if (await secureTempDir.exists()) {
      await for (final entity in secureTempDir.list()) {
        await entity.delete(recursive: true);
      }
    }
  }

  /// Supprime les fichiers provisoires (`.part`) laissés par une interruption.
  Future<void> purgePartialFiles() async {
    for (final dir in [filesDir, thumbsDir]) {
      if (!await dir.exists()) {
        continue;
      }
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.part')) {
          await entity.delete();
        }
      }
    }
  }

  /// Efface tout le coffre (base, fichiers, miniatures, serrure, temporaires).
  Future<void> deleteEverything() async {
    for (final dir in [vaultDir, secureTempDir]) {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }
}
