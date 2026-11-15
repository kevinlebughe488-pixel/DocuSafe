import 'dart:convert';
import 'dart:typed_data';

import '../../errors/app_exception.dart';
import '../crypto/argon2_params.dart';

/// Une « serrure » : la clé du coffre, chiffrée en AES-256-GCM avec une clé
/// issue d'un secret (code ou clé de récupération) (docs/04-securite.md §4).
///
/// Format JSON, version 1 :
/// ```json
/// {"v":1,"kdf":"argon2id","m":19456,"t":2,"p":1,"len":6,
///  "salt":"…","nonce":"…","wrapped":"…"}
/// ```
/// Les paramètres de dérivation sont enregistrés pour pouvoir évoluer.
/// `len` (longueur du code, serrure du code seulement) est absent des
/// serrures créées avant le 15/11/2026.
final class VaultKeySlot {
  const VaultKeySlot({
    required this.kdf,
    required this.salt,
    required this.nonce,
    required this.wrappedKey,
    this.argon2,
    this.pinLength,
  });

  static const int version = 1;
  static const String kdfArgon2id = 'argon2id';
  static const String kdfHkdf = 'hkdf';

  /// Étiquettes d'authentification : une serrure du code ne peut pas être
  /// rejouée comme serrure de récupération.
  static final Uint8List aadPin = Uint8List.fromList(
    utf8.encode('docusafe/v1/slot/pin'),
  );
  static final Uint8List aadRecovery = Uint8List.fromList(
    utf8.encode('docusafe/v1/slot/recovery'),
  );

  /// `argon2id` (code) ou `hkdf` (clé de récupération).
  final String kdf;
  final Uint8List salt;
  final Uint8List nonce;

  /// Clé du coffre chiffrée, sceau compris.
  final Uint8List wrappedKey;

  /// Paramètres Argon2id, présents si [kdf] vaut `argon2id`.
  final Argon2Params? argon2;

  /// Longueur du code : l'écran de déverrouillage valide tout seul dès
  /// qu'elle est atteinte. Information non secrète (tous les nouveaux codes
  /// ont 6 chiffres). `null` dans une ancienne serrure : bouton « Confirmer ».
  final int? pinLength;

  String encode() => jsonEncode({
    'v': version,
    'kdf': kdf,
    if (argon2 != null) ...argon2!.toJson(),
    'len': ?pinLength,
    'salt': base64Encode(salt),
    'nonce': base64Encode(nonce),
    'wrapped': base64Encode(wrappedKey),
  });

  static VaultKeySlot decode(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      if (json['v'] != version) {
        throw CryptoException.unsupportedVersion;
      }
      final kdf = json['kdf']! as String;
      return VaultKeySlot(
        kdf: kdf,
        argon2: kdf == kdfArgon2id ? Argon2Params.fromJson(json) : null,
        pinLength: json['len'] as int?,
        salt: base64Decode(json['salt']! as String),
        nonce: base64Decode(json['nonce']! as String),
        wrappedKey: base64Decode(json['wrapped']! as String),
      );
    } on CryptoException {
      rethrow;
    } on Object {
      throw CryptoException.badFormat;
    }
  }
}
