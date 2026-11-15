import '../../app/l10n/generated/app_localizations.dart';

/// Formats courts des durées : « 28 s », « 1 min », « 2 min 05 s ».
abstract final class DurationFormat {
  static String short(AppLocalizations l10n, Duration d) {
    final seconds = d.inSeconds.clamp(0, 1 << 31);
    if (seconds < 60) {
      return l10n.durationSeconds(seconds);
    }
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    if (rest == 0) {
      return l10n.durationMinutes(minutes);
    }
    return l10n.durationMinutesSeconds(minutes, rest);
  }
}
