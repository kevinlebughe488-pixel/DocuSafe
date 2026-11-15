import 'dart:typed_data';

import '../../config/app_config.dart';
import '../../errors/app_exception.dart';
import '../../utils/bytes.dart';

/// En-tête d'un fichier chiffré au format `DSF1` (docs/04-securite.md §8).
///
/// | Partie | Taille | Contenu |
/// |---|---|---|
/// | Signature | 4 | `DSF1` |
/// | Version, algorithme, options | 4 | 1, 1 (AES-256-GCM), 0, 0 |
/// | Taille des blocs | 4 | 1 Mo par défaut, poids faible en premier |
/// | Sel | 16 | Aléatoire, unique par fichier |
/// | Réservé | 4 | Zéros |
final class DsfHeader {
  const DsfHeader({required this.blockSize, required this.salt})
    : assert(salt.length == saltLength);

  static const int length = 32;
  static const int saltLength = 16;
  static const int formatVersion = 1;
  static const int algorithmAesGcm = 1;
  static final Uint8List magic = Uint8List.fromList('DSF1'.codeUnits);

  /// Taille d'un bloc en clair. Au moins 4 Ko, au plus 16 Mo.
  final int blockSize;
  final Uint8List salt;

  /// Taille d'un bloc une fois chiffré (données + sceau).
  int get encryptedBlockSize => blockSize + 16;

  Uint8List encode() {
    final out = Uint8List(length);
    out.setRange(0, 4, magic);
    out[4] = formatVersion;
    out[5] = algorithmAesGcm;
    out.setRange(8, 12, Bytes.uint32le(blockSize));
    out.setRange(12, 28, salt);
    return out;
  }

  static DsfHeader decode(Uint8List bytes) {
    if (bytes.length < length) {
      throw CryptoException.badFormat;
    }
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != magic[i]) {
        throw CryptoException.badFormat;
      }
    }
    if (bytes[4] != formatVersion) {
      throw CryptoException.unsupportedVersion;
    }
    if (bytes[5] != algorithmAesGcm) {
      throw CryptoException.unsupportedVersion;
    }
    final blockSize = ByteData.sublistView(bytes, 8, 12).getUint32(
      0,
      Endian.little,
    );
    if (blockSize < 4096 || blockSize > 16 * 1024 * 1024) {
      throw CryptoException.badFormat;
    }
    return DsfHeader(
      blockSize: blockSize,
      salt: Uint8List.fromList(bytes.sublist(12, 28)),
    );
  }

  /// En-tête par défaut avec un sel neuf.
  static DsfHeader create(Uint8List salt) =>
      DsfHeader(blockSize: AppConfig.cipherBlockSize, salt: salt);
}
