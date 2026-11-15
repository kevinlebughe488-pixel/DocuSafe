import '../utils/date_only.dart';

/// Calcul des rappels d'échéance (cahier des charges §3.10), en Dart pur.
abstract final class ReminderPlanner {
  /// Délais par défaut : 90, 30, 7 jours avant, puis le jour même.
  static const List<int> defaultOffsets = [90, 30, 7, 0];

  /// Heure d'envoi par défaut.
  static const String defaultTime = '09:00';

  /// Au plus 60 rappels programmés à l'avance (limite d'iOS : 64).
  static const int maxScheduled = 60;

  /// Lit « HH:mm » ; retourne 09:00 si la valeur est invalide.
  static (int, int) parseTime(String? text) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text ?? '');
    if (m != null) {
      final h = int.parse(m[1]!);
      final min = int.parse(m[2]!);
      if (h < 24 && min < 60) {
        return (h, min);
      }
    }
    return (9, 0);
  }

  static String formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Moment local du rappel : [offsetDays] jours avant [expiration], à
  /// l'heure d'envoi.
  static DateTime dateFor(DateOnly expiration, int offsetDays, (int, int) time) =>
      DateTime(
        expiration.year,
        expiration.month,
        expiration.day - offsetDays,
        time.$1,
        time.$2,
      );

  /// Délais triés du plus éloigné au plus proche, sans doublon.
  static List<int> normalizeOffsets(Iterable<int> offsets) {
    final list = offsets.where((o) => o >= 0 && o <= 3650).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return list;
  }
}
