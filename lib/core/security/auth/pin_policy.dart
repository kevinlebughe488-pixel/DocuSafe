import '../../config/app_config.dart';
import '../../errors/app_exception.dart';

/// Règles du code (docs/04-securite.md §5, choix D5).
abstract final class PinPolicy {
  static final RegExp _digits = RegExp(r'^\d+$');

  /// Vérifie un code. Lève [ValidationException.pinFormat] ou
  /// [ValidationException.pinTooSimple].
  static void validate(String pin) {
    if (pin.length < AppConfig.pinMinLength ||
        pin.length > AppConfig.pinMaxLength ||
        !_digits.hasMatch(pin)) {
      throw ValidationException.pinFormat;
    }
    if (isTooSimple(pin)) {
      throw ValidationException.pinTooSimple;
    }
  }

  /// Vrai pour les suites et répétitions évidentes : `000000`, `123456`,
  /// `654321`, `121212`, `112233`…
  static bool isTooSimple(String pin) {
    final codes = pin.codeUnits;
    if (codes.toSet().length == 1) {
      return true;
    }
    final delta = codes[1] - codes[0];
    if (delta == 1 || delta == -1) {
      var sequence = true;
      for (var i = 1; i < codes.length; i++) {
        if (codes[i] - codes[i - 1] != delta) {
          sequence = false;
          break;
        }
      }
      if (sequence) {
        return true;
      }
    }
    // Motif court répété (12 12 12, 123 123, 11 22 33 n'est pas couvert ici).
    for (var period = 1; period <= pin.length ~/ 2; period++) {
      if (pin.length % period != 0) {
        continue;
      }
      final pattern = pin.substring(0, period);
      if (pattern * (pin.length ~/ period) == pin) {
        return true;
      }
    }
    // Paires de chiffres identiques croissants ou décroissants : 112233.
    if (pin.length.isEven) {
      var paired = true;
      for (var i = 0; i < pin.length; i += 2) {
        if (pin[i] != pin[i + 1]) {
          paired = false;
          break;
        }
      }
      if (paired) {
        final heads = [for (var i = 0; i < pin.length; i += 2) codes[i]];
        final step = heads[1] - heads[0];
        if (step == 1 || step == -1) {
          var sequence = true;
          for (var i = 1; i < heads.length; i++) {
            if (heads[i] - heads[i - 1] != step) {
              sequence = false;
              break;
            }
          }
          if (sequence) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
