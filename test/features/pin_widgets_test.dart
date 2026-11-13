import 'package:docusafe/core/widgets/pin_dots.dart';
import 'package:docusafe/features/auth/presentation/widgets/pin_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('clavier : saisie, effacement, validation à partir de 6', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      wrap(
        PinEntry(
          onSubmit: (pin) => submitted = pin,
          submitLabel: 'Continuer',
        ),
      ),
    );

    final submit = find.widgetWithText(FilledButton, 'Continuer');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await typePin(tester, '20491');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await typePin(tester, '5');
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(find.bySemanticsLabel('Effacer le dernier chiffre'));
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await typePin(tester, '7');
    await tester.tap(submit);
    await tester.pump();
    expect(submitted, '204917');
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
          submitLabel: 'Confirmer',
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
