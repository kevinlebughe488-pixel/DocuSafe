import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Profil local : nom facultatif affiché sur l'accueil (écran 18).
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  testWidgets('saisir un nom, le voir sur l\'accueil, puis l\'effacer', (tester) async {
    usePhoneSize(tester);
    await tester.runAsync(() async {
      final service = ProviderContainer(overrides: env.overrides()).read(vaultServiceProvider);
      final session = await service.commitSetup(await service.prepareSetup('204915'));
      await session.close();
    });
    await tester.pumpWidget(
      ProviderScope(overrides: env.overrides(), child: testAppChild()),
    );
    await settle(tester, rounds: 8);
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    await tester.runAsync(
      () => container.read(vaultControllerProvider.notifier).unlockWithPin('204915'),
    );
    await settle(tester, rounds: 8);
    expect(find.textContaining('Bonjour'), findsNothing);

    container.read(routerProvider).go(Routes.settings);
    await settle(tester, rounds: 8);
    expect(find.text("Nom affiché sur l'accueil"), findsOneWidget);
    await tester.tap(find.text('Profil local'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '  Awa   Diallo ');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester, rounds: 10);
    expect(find.text('Awa Diallo'), findsOneWidget);

    container.read(routerProvider).go(Routes.home);
    await settle(tester, rounds: 8);
    expect(find.text('Bonjour Awa Diallo'), findsOneWidget);

    // Un champ vide efface le nom.
    container.read(routerProvider).go(Routes.settings);
    await settle(tester, rounds: 8);
    await tester.tap(find.text('Profil local'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester, rounds: 10);
    expect(find.text("Nom affiché sur l'accueil"), findsOneWidget);
    await teardownApp(tester);
  });
}
