import 'dart:typed_data';

import 'argon2_params.dart';

/// Primitives cryptographiques utilisées par DocSafe.
///
/// C'est le **seul** endroit où un paquet de cryptographie est appelé
/// (docs/02-architecture.md, règle 3). Changer de paquet ne touche que
/// l'implémentation de cette interface.
abstract interface class CryptoEngine {
  /// Longueur du nonce AES-GCM (12 octets, valeur recommandée).
  static const int gcmNonceLength = 12;

  /// Longueur du sceau d'authenticité AES-GCM.
  static const int gcmTagLength = 16;

  /// Longueur des clés AES-256.
  static const int keyLength = 32;

  /// Octets aléatoires sécurisés.
  Uint8List randomBytes(int length);

  /// AES-256-GCM. Retourne `données chiffrées ‖ sceau (16 octets)`.
  Future<Uint8List> aesGcmEncrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    Uint8List? aad,
  });

  /// AES-256-GCM. Lève [CryptoException.integrity] si le sceau est faux.
  Future<Uint8List> aesGcmDecrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertextWithTag,
    Uint8List? aad,
  });

  /// HKDF-SHA256 : dérive [length] octets d'une clé maîtresse.
  Future<Uint8List> hkdfSha256({
    required Uint8List inputKey,
    required Uint8List salt,
    required Uint8List info,
    int length = keyLength,
  });

  /// Argon2id : calcul volontairement lent d'une clé à partir du code.
  ///
  /// Exécuté hors du fil d'exécution de l'interface par l'implémentation.
  Future<Uint8List> argon2id({
    required Uint8List password,
    required Uint8List salt,
    required Argon2Params params,
    int length = keyLength,
  });
}
