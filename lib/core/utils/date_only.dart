/// Date sans heure ni fuseau horaire (docs/03-modele-de-donnees.md §4).
///
/// Un passeport qui expire le 12 mars expire le 12 mars partout : la valeur
/// est stockée sous la forme `AAAA-MM-JJ`.
final class DateOnly implements Comparable<DateOnly> {
  const DateOnly(this.year, this.month, this.day);

  factory DateOnly.fromDateTime(DateTime dt) =>
      DateOnly(dt.year, dt.month, dt.day);

  factory DateOnly.today([DateTime Function() clock = DateTime.now]) =>
      DateOnly.fromDateTime(clock());

  /// Lit `AAAA-MM-JJ`. Retourne `null` si la forme est invalide.
  static DateOnly? tryParse(String? text) {
    if (text == null) {
      return null;
    }
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) {
      return null;
    }
    final y = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    final d = int.parse(match[3]!);
    final check = DateTime.utc(y, m, d);
    if (check.year != y || check.month != m || check.day != d) {
      return null;
    }
    return DateOnly(y, m, d);
  }

  final int year;
  final int month;
  final int day;

  /// Forme stockée : `AAAA-MM-JJ`.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Minuit local de ce jour (pour les calculs de rappels et l'affichage).
  DateTime toLocalDateTime() => DateTime(year, month, day);

  /// Nombre de jours entre [from] et cette date (négatif si passée).
  int daysFrom(DateOnly from) => DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  DateOnly addDays(int days) =>
      DateOnly.fromDateTime(DateTime.utc(year, month, day + days));

  @override
  int compareTo(DateOnly other) => toIso().compareTo(other.toIso());

  @override
  bool operator ==(Object other) =>
      other is DateOnly &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
