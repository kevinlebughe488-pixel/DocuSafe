import '../../config/app_config.dart';
import '../../errors/app_exception.dart';

/// Règles du code (docs/04-securite.md §5, choix D5).
abstract final class PinPolicy {
  static final RegExp _digits = RegExp(r'^\d+$');

  /// Vérifie un nouveau code : 6 chiffres exactement. Lève
  /// [ValidationException.pinFormat] ou [ValidationException.pinTooSimple].
  static void validate(String pin) {
    if (pin.length != AppConfig.pinLength || !_digits.hasMatch(pin)) {
      throw ValidationException.pinFormat;
    }
    if (isTooSimple(pin)) {
      throw ValidationException.pinTooSimple;
    }
  }

  /// Vrai pour les deux cas les plus évidents seulement : six chiffres
  /// identiques (`000000`, `111111`…) et les suites (`123456`, `654321`…).
  /// Les autres codes, comme `112233` ou `121212`, sont acceptés (D5, révisée
  /// le 15/11/2026 : des règles plus strictes rendaient le choix difficile).
  static bool isTooSimple(String pin) {
    final codes = pin.codeUnits;
    if (codes.toSet().length == 1) {
      return true;
    }
    final delta = codes[1] - codes[0];
    if (delta != 1 && delta != -1) {
      return false;
    }
    for (var i = 2; i < codes.length; i++) {
      if (codes[i] - codes[i - 1] != delta) {
        return false;
      }
    }
    return true;
  }
}
