import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' hide SecureRandom;
import 'package:cryptography/dart.dart' show DartArgon2id;

import '../../errors/app_exception.dart';
import '../../utils/secure_random.dart';
import 'argon2_params.dart';
import 'crypto_engine.dart';

/// Implémentation de [CryptoEngine] avec le paquet `cryptography`.
///
/// Dans l'application, `FlutterCryptography.enable()` (paquet
/// `cryptography_flutter`) est appelé au démarrage : AES-GCM passe alors par
/// les API natives d'Android et d'iOS quand elles existent. Argon2id est
/// calculé en Dart pur dans un isolate séparé.
final class DartCryptoEngine implements CryptoEngine {
  const DartCryptoEngine();

  static final AesGcm _aesGcm = AesGcm.with256bits();

  @override
  Uint8List randomBytes(int length) => SecureRandom.bytes(length);

  @override
  Future<Uint8List> aesGcmEncrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List plaintext,
    Uint8List? aad,
  }) async {
    _checkKey(key);
    final box = await _aesGcm.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
      aad: aad ?? const <int>[],
    );
    final out = Uint8List(box.cipherText.length + box.mac.bytes.length);
    out.setRange(0, box.cipherText.length, box.cipherText);
    out.setRange(box.cipherText.length, out.length, box.mac.bytes);
    return out;
  }

  @override
  Future<Uint8List> aesGcmDecrypt({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertextWithTag,
    Uint8List? aad,
  }) async {
    _checkKey(key);
    if (ciphertextWithTag.length < CryptoEngine.gcmTagLength) {
      throw CryptoException.integrity;
    }
    final split = ciphertextWithTag.length - CryptoEngine.gcmTagLength;
    final box = SecretBox(
      Uint8List.sublistView(ciphertextWithTag, 0, split),
      nonce: nonce,
      mac: Mac(Uint8List.sublistView(ciphertextWithTag, split)),
    );
    try {
      final clear = await _aesGcm.decrypt(
        box,
        secretKey: SecretKey(key),
        aad: aad ?? const <int>[],
      );
      return clear is Uint8List ? clear : Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw CryptoException.integrity;
    }
  }

  @override
  Future<Uint8List> hkdfSha256({
    required Uint8List inputKey,
    required Uint8List salt,
    required Uint8List info,
    int length = CryptoEngine.keyLength,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: length);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(inputKey),
      nonce: salt,
      info: info,
    );
    return Uint8List.fromList(await derived.extractBytes());
  }

  @override
  Future<Uint8List> argon2id({
    required Uint8List password,
    required Uint8List salt,
    required Argon2Params params,
    int length = CryptoEngine.keyLength,
  }) {
    // Le calcul dure volontairement longtemps : il s'exécute dans un isolate
    // pour ne jamais figer l'interface (docs/02-architecture.md §8).
    return Isolate.run(
      () => _argon2idSync(password, salt, params, length),
      debugName: 'argon2id',
    );
  }

  static Future<Uint8List> _argon2idSync(
    Uint8List password,
    Uint8List salt,
    Argon2Params params,
    int length,
  ) async {
    final algorithm = DartArgon2id(
      parallelism: params.parallelism,
      memory: params.memoryKiB,
      iterations: params.iterations,
      hashLength: length,
    );
    final key = await algorithm.deriveKey(
      secretKey: SecretKey(password),
      nonce: salt,
    );
    return Uint8List.fromList(await key.extractBytes());
  }

  static void _checkKey(Uint8List key) {
    if (key.length != CryptoEngine.keyLength) {
      throw ArgumentError.value(key.length, 'key', 'AES-256 exige 32 octets');
    }
  }
}
