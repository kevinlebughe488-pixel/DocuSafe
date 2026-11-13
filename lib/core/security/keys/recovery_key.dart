import 'dart:typed_data';

import '../../errors/app_exception.dart';
import '../../utils/secure_random.dart';

/// Clé de récupération (docs/04-securite.md §7).
///
/// 160 bits aléatoires, écrits avec 32 symboles sans caractères ambigus
/// (ni I, L, O, U) : 32 caractères, en 8 groupes de 4.
final class RecoveryKey {
  RecoveryKey._(this.bytes);

  /// Alphabet de 32 symboles : chiffres puis lettres, sans I, L, O, U.
  static const String alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const int byteLength = 20;
  static const int charLength = 32;
  static const int groupSize = 4;

  /// Les 20 octets (160 bits) de la clé.
  final Uint8List bytes;

  /// Nouvelle clé aléatoire.
  factory RecoveryKey.generate() =>
      RecoveryKey._(SecureRandom.bytes(byteLength));

  /// Lit une clé saisie par l'utilisateur. Tirets, espaces et minuscules sont
  /// tolérés. Lève [AuthException.recoveryKeyInvalid] si la forme est fausse.
  factory RecoveryKey.parse(String input) {
    final cleaned = normalizeInput(input);
    if (cleaned.length != charLength) {
      throw const AuthException.recoveryKeyInvalid();
    }
    final out = Uint8List(byteLength);
    var buffer = 0;
    var bits = 0;
    var index = 0;
    for (final ch in cleaned.split('')) {
      final value = alphabet.indexOf(ch);
      if (value < 0) {
        throw const AuthException.recoveryKeyInvalid();
      }
      buffer = (buffer << 5) | value;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out[index++] = (buffer >> bits) & 0xff;
        buffer &= (1 << bits) - 1;
      }
    }
    return RecoveryKey._(out);
  }

  /// Supprime tirets et espaces, passe en majuscules.
  static String normalizeInput(String input) =>
      input.replaceAll(RegExp(r'[\s\-–—]'), '').toUpperCase();

  /// Nombre de symboles valides déjà saisis (pour « 18 caractères sur 32 »).
  static int countValidChars(String input) =>
      normalizeInput(input).split('').where(alphabet.contains).length;

  /// Forme affichée : `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX`.
  String get display {
    final chars = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final b in bytes) {
      buffer = (buffer << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        chars.write(alphabet[(buffer >> bits) & 0x1f]);
        buffer &= (1 << bits) - 1;
      }
    }
    final s = chars.toString();
    final groups = <String>[];
    for (var i = 0; i < s.length; i += groupSize) {
      groups.add(s.substring(i, i + groupSize));
    }
    return groups.join('-');
  }
}
