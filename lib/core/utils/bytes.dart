import 'dart:typed_data';

/// Petits utilitaires sur les tableaux d'octets.
abstract final class Bytes {
  /// Comparaison en temps constant : ne révèle pas la position de la
  /// première différence.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Écrase le contenu avec des zéros (meilleur effort, voir limite n°3 de
  /// docs/04-securite.md).
  static void wipe(List<int>? data) {
    if (data == null) {
      return;
    }
    for (var i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }

  /// Concatène plusieurs tableaux.
  static Uint8List concat(List<List<int>> parts) {
    var total = 0;
    for (final p in parts) {
      total += p.length;
    }
    final out = Uint8List(total);
    var offset = 0;
    for (final p in parts) {
      out.setRange(offset, offset + p.length, p);
      offset += p.length;
    }
    return out;
  }

  /// Représentation hexadécimale en minuscules.
  static String toHex(List<int> data) {
    final sb = StringBuffer();
    for (final b in data) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Entier non signé de 32 bits, poids faible en premier.
  static Uint8List uint32le(int value) {
    final out = Uint8List(4);
    ByteData.view(out.buffer).setUint32(0, value, Endian.little);
    return out;
  }

  /// Entier non signé de 64 bits, poids faible en premier.
  static Uint8List uint64le(int value) {
    final out = Uint8List(8);
    ByteData.view(out.buffer).setUint64(0, value, Endian.little);
    return out;
  }
}
