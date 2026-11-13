import 'dart:convert';
import 'dart:typed_data';

import 'crypto_engine.dart';

/// Dérivation des clés de travail à partir de la clé du coffre
/// (docs/04-securite.md §4.1).
///
/// Chaque usage a sa propre étiquette : aucune clé ne sert à deux choses.
final class KeyDerivation {
  const KeyDerivation(this._crypto);

  final CryptoEngine _crypto;

  /// Étiquettes HKDF. Ne jamais les modifier : elles font partie du format.
  static final Uint8List _dbInfo = _label('docusafe/v1/database');
  static final Uint8List _filesInfo = _label('docusafe/v1/files');
  static final Uint8List _thumbsInfo = _label('docusafe/v1/thumbnails');
  static final Uint8List _fileKeyInfo = _label('docusafe/v1/file-key');
  static final Uint8List _recoveryInfo = _label('docusafe/v1/recovery-slot');

  /// Sel fixe pour les clés de travail : la clé du coffre est déjà aléatoire,
  /// c'est l'étiquette qui sépare les usages.
  static final Uint8List _noSalt = Uint8List(0);

  static Uint8List _label(String s) => Uint8List.fromList(utf8.encode(s));

  /// Clé de la base de données (32 octets).
  Future<Uint8List> databaseKey(Uint8List vaultKey) => _crypto.hkdfSha256(
    inputKey: vaultKey,
    salt: _noSalt,
    info: _dbInfo,
  );

  /// Racine des clés de fichiers. Chaque fichier en dérive sa propre clé.
  Future<Uint8List> filesRootKey(Uint8List vaultKey) => _crypto.hkdfSha256(
    inputKey: vaultKey,
    salt: _noSalt,
    info: _filesInfo,
  );

  /// Racine des clés de miniatures.
  Future<Uint8List> thumbnailsRootKey(Uint8List vaultKey) =>
      _crypto.hkdfSha256(
        inputKey: vaultKey,
        salt: _noSalt,
        info: _thumbsInfo,
      );

  /// Clé d'un fichier précis : racine + sel propre au fichier.
  Future<Uint8List> fileKey(Uint8List rootKey, Uint8List fileSalt) =>
      _crypto.hkdfSha256(
        inputKey: rootKey,
        salt: fileSalt,
        info: _fileKeyInfo,
      );

  /// Clé qui enferme la clé du coffre dans la serrure de récupération.
  Future<Uint8List> recoverySlotKey(
    Uint8List recoveryKeyBytes,
    Uint8List salt,
  ) => _crypto.hkdfSha256(
    inputKey: recoveryKeyBytes,
    salt: salt,
    info: _recoveryInfo,
  );
}
