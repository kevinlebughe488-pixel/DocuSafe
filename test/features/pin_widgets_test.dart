import 'package:docusafe/core/widgets/pin_dots.dart';
import 'package:docusafe/features/auth/presentation/widgets/pin_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('code de 6 chiffres : validé tout seul, sans bouton', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(wrap(PinEntry(onSubmit: submitted.add)));
    expect(find.byType(FilledButton), findsNothing);

    // Effacement avant le sixième chiffre : rien n'est validé.
    await typePin(tester, '20491');
    await tester.tap(find.bySemanticsLabel('Effacer le dernier chiffre'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(submitted, isEmpty);

    await typePin(tester, '17');
    expect(submitted, ['204917']);
    // Les points sont vidés pour la saisie suivante.
    expect(tester.widget<PinDots>(find.byType(PinDots)).filled, 0);
  });

  testWidgets('effacer le sixième chiffre aussitôt annule la validation', (tester) async {
    final submitted = <String>[];
    await tester.pumpWidget(wrap(PinEntry(onSubmit: submitted.add)));
    for (final d in '204915'.split('')) {
      await tester.tap(find.widgetWithText(InkWell, d).last);
      await tester.pump();
    }
    await tester.tap(find.bySemanticsLabel('Effacer le dernier chiffre'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(submitted, isEmpty);
    expect(tester.widget<PinDots>(find.byType(PinDots)).filled, 5);
  });

  testWidgets('ancien coffre : code de 6 à 12 chiffres, bouton Confirmer', (tester) async {
    String? submitted;
    await tester.pumpWidget(
      wrap(
        PinEntry(
          onSubmit: (pin) => submitted = pin,
          length: null,
          submitLabel: 'Confirmer',
        ),
      ),
    );
    final submit = find.widgetWithText(FilledButton, 'Confirmer');
    await typePin(tester, '20491');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await typePin(tester, '573');
    expect(submitted, isNull, reason: 'pas de validation automatique');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pump();
    expect(submitted, '20491573');
  });

  testWidgets('points : six au minimum, un par chiffre au-delà', (tester) async {
    await tester.pumpWidget(wrap(const PinDots(filled: 2)));
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
    await tester.pumpWidget(wrap(const PinDots(filled: 8)));
    expect(find.byType(AnimatedContainer), findsNWidgets(8));
  });

  testWidgets('clavier désactivé pendant une attente', (tester) async {
    var called = false;
    await tester.pumpWidget(
      wrap(
        PinEntry(
          onSubmit: (_) => called = true,
          enabled: false,
          message: 'Réessayez dans 28 s',
          messageIsError: true,
        ),
      ),
    );
    expect(find.text('Réessayez dans 28 s'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, '1'), warnIfMissed: false);
    await tester.pump();
    expect(called, isFalse);
  });
}
