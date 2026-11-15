import 'dart:typed_data';

import '../../database/app_database.dart';
import '../../utils/bytes.dart';

/// Tout ce qui n'existe que lorsque le coffre est déverrouillé
/// (docs/02-architecture.md §6) : la clé du coffre, les clés de travail et la
/// base ouverte. [close] efface les clés et ferme la base.
final class VaultSession {
  VaultSession({
    required this._vaultKey,
    required this._filesRootKey,
    required this._thumbnailsRootKey,
    required this.database,
  });

  final Uint8List _vaultKey;
  final Uint8List _filesRootKey;
  final Uint8List _thumbnailsRootKey;
  final AppDatabase database;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Clé du coffre. Réservée aux opérations sur les serrures (changer le code,
  /// activer la biométrie, nouvelle clé de récupération).
  Uint8List get vaultKey => _checked(_vaultKey);

  /// Racine des clés de fichiers.
  Uint8List get filesRootKey => _checked(_filesRootKey);

  /// Racine des clés de miniatures.
  Uint8List get thumbnailsRootKey => _checked(_thumbnailsRootKey);

  Uint8List _checked(Uint8List key) {
    if (_closed) {
      throw StateError('Session fermée');
    }
    return key;
  }

  /// Ferme la base et écrase les clés en mémoire.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await database.close();
    } finally {
      Bytes.wipe(_vaultKey);
      Bytes.wipe(_filesRootKey);
      Bytes.wipe(_thumbnailsRootKey);
    }
  }
}
