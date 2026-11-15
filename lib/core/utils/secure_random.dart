import 'dart:math';
import 'dart:typed_data';

/// Générateur aléatoire sécurisé du système.
abstract final class SecureRandom {
  static final Random _random = Random.secure();

  /// [length] octets aléatoires.
  static Uint8List bytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  /// Identifiant unique au format UUID version 4 (36 caractères).
  static String uuid() {
    final b = bytes(16);
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final hex = StringBuffer();
    for (var i = 0; i < 16; i++) {
      hex.write(b[i].toRadixString(16).padLeft(2, '0'));
      if (i == 3 || i == 5 || i == 7 || i == 9) {
        hex.write('-');
      }
    }
    return hex.toString();
  }
}
