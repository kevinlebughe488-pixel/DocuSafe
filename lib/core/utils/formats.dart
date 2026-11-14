import 'package:intl/intl.dart';

import '../../app/l10n/generated/app_localizations.dart';
import 'date_only.dart';

/// Formats français des dates et des tailles (docs/07-design.md §2 :
/// « 14 févr. 2027 · 1,2 Mo · 09:00 »).
abstract final class Formats {
  static final DateFormat _day = DateFormat('d MMM yyyy', 'fr');
  static final DateFormat _dayShort = DateFormat('d MMM', 'fr');
  static final DateFormat _time = DateFormat('HH:mm', 'fr');

  /// « 14 févr. 2027 ».
  static String date(DateOnly d) => _day.format(d.toLocalDateTime());

  /// « 14 févr. 2027 » pour un instant.
  static String dateTime(DateTime dt) => _day.format(dt.toLocal());

  /// « Aujourd'hui », « Hier », « 10 nov. » ou « 3 mai 2025 ».
  static String relativeDay(
    AppLocalizations l10n,
    DateTime dt, {
    DateTime? now,
  }) {
    final today = DateOnly.fromDateTime(now ?? DateTime.now());
    final day = DateOnly.fromDateTime(dt.toLocal());
    final diff = today.daysFrom(day);
    if (diff == 0) {
      return l10n.dateToday;
    }
    if (diff == 1) {
      return l10n.dateYesterday;
    }
    if (day.year == today.year) {
      return _dayShort.format(dt.toLocal());
    }
    return _day.format(dt.toLocal());
  }

  /// « Aujourd'hui à 09:12 », « Hier », « 10 nov. ».
  static String relativeDayTime(
    AppLocalizations l10n,
    DateTime dt, {
    DateTime? now,
  }) {
    final today = DateOnly.fromDateTime(now ?? DateTime.now());
    final day = DateOnly.fromDateTime(dt.toLocal());
    if (today.daysFrom(day) == 0) {
      return l10n.dateTodayAt(_time.format(dt.toLocal()));
    }
    return relativeDay(l10n, dt, now: now);
  }

  /// « 312 o », « 1,2 Mo », « 3,1 Go ». Base 1 000, séparateur décimal
  /// français.
  static String fileSize(int bytes) {
    if (bytes < 1000) {
      return '$bytes o';
    }
    const units = ['ko', 'Mo', 'Go'];
    var value = bytes / 1000;
    var unit = 0;
    while (value >= 1000 && unit < units.length - 1) {
      value /= 1000;
      unit++;
    }
    final text = value >= 100
        ? value.round().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',').replaceAll(',0', '');
    return '$text ${units[unit]}';
  }
}

/// État d'une échéance (docs/07-design.md §3.2 : trois états seulement).
enum ExpiryStatus { expired, soon, later }

final class ExpiryInfo {
  const ExpiryInfo(this.status, this.label);

  final ExpiryStatus status;

  /// Texte de l'étiquette : « Expiré », « J-7 », « 3 mois », « 1 an 6 mois ».
  final String label;

  /// Calcule l'état d'une date d'expiration par rapport à [today].
  static ExpiryInfo of(AppLocalizations l10n, DateOnly expiration, DateOnly today) {
    final days = expiration.daysFrom(today);
    if (days < 0) {
      return ExpiryInfo(ExpiryStatus.expired, l10n.expiryExpired);
    }
    if (days <= 30) {
      return ExpiryInfo(ExpiryStatus.soon, l10n.expiryInDays(days));
    }
    // Mois de calendrier entiers entre les deux dates.
    var months =
        (expiration.year - today.year) * 12 + (expiration.month - today.month);
    if (expiration.day < today.day) {
      months--;
    }
    if (months < 1) {
      months = 1;
    }
    if (months < 12) {
      return ExpiryInfo(ExpiryStatus.later, l10n.expiryInMonths(months));
    }
    final years = months ~/ 12;
    final rest = months % 12;
    return ExpiryInfo(
      ExpiryStatus.later,
      rest == 0
          ? l10n.expiryInYears(years)
          : l10n.expiryInYearsMonths(years, rest),
    );
  }
}
