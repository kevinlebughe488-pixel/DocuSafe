import 'package:docusafe/app/l10n/generated/app_localizations.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:docusafe/core/utils/formats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    await initializeDateFormatting('fr');
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  test('tailles de fichier en français', () {
    expect(Formats.fileSize(312), '312 o');
    expect(Formats.fileSize(1200), '1,2 ko');
    expect(Formats.fileSize(2 * 1000 * 1000), '2 Mo');
    expect(Formats.fileSize(1234567), '1,2 Mo');
    expect(Formats.fileSize(312 * 1000 * 1000), '312 Mo');
    expect(Formats.fileSize(3100 * 1000 * 1000), '3,1 Go');
  });

  test('dates', () {
    expect(Formats.date(const DateOnly(2027, 2, 14)), '14 févr. 2027');
    final now = DateTime(2026, 11, 13, 10);
    expect(Formats.relativeDay(l10n, DateTime(2026, 11, 13, 8), now: now), "Aujourd'hui");
    expect(Formats.relativeDay(l10n, DateTime(2026, 11, 12, 23), now: now), 'Hier');
    expect(Formats.relativeDay(l10n, DateTime(2026, 11, 10), now: now), '10 nov.');
    expect(Formats.relativeDay(l10n, DateTime(2025, 5, 3), now: now), '3 mai 2025');
    expect(
      Formats.relativeDayTime(l10n, DateTime(2026, 11, 13, 9, 12), now: now),
      "Aujourd'hui à 09:12",
    );
  });

  test('échéances : trois états', () {
    const today = DateOnly(2026, 11, 13);
    ExpiryInfo info(DateOnly d) => ExpiryInfo.of(l10n, d, today);
    expect(info(const DateOnly(2026, 11, 2)).status, ExpiryStatus.expired);
    expect(info(const DateOnly(2026, 11, 2)).label, 'Expiré');
    expect(info(const DateOnly(2026, 11, 20)).label, 'J-7');
    expect(info(const DateOnly(2026, 11, 20)).status, ExpiryStatus.soon);
    expect(info(const DateOnly(2026, 11, 13)).label, "Aujourd'hui");
    expect(info(const DateOnly(2027, 2, 14)).label, '3 mois');
    expect(info(const DateOnly(2027, 2, 14)).status, ExpiryStatus.later);
    expect(info(const DateOnly(2028, 6, 9)).label, '1 an 6 mois');
    expect(info(const DateOnly(2028, 11, 13)).label, '2 ans');
  });
}
