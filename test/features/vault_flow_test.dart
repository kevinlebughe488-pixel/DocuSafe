import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/lock/vault_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Parcours complet : onboarding → création du coffre → tableau de bord →
/// verrouillage → déverrouillage (docs/05-parcours-utilisateurs.md §1 et §2).
void main() {
  late TestEnvironment env;

  setUp(() async {
    env = await TestEnvironment.create();
  });

  tearDown(() => env.dispose());

  testWidgets('création du coffre puis verrouillage et déverrouillage', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.pumpWidget(testApp(env));
    await settle(tester);

    // Aucun coffre : onboarding.
    expect(find.text('Bienvenue dans DocuSafe'), findsOneWidget);
    await tester.tap(find.text('Passer'));
    await settle(tester, rounds: 5);

    // Étape 1 : code, puis confirmation. Rien n'est écrit avant la confirmation.
    expect(find.text('Choisissez votre code'), findsOneWidget);
    await typePin(tester, '204915');
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(find.text('Confirmez votre code'), findsOneWidget);
    expect(env.store.values, isEmpty);
    await typePin(tester, '204915');
    await tester.tap(find.text('Continuer'));
    await settle(tester, rounds: 40);

    // Pas de biométrie dans les tests : tableau de bord directement, avec le
    // rappel de la clé de récupération (D6 révisée).
    // Le compteur et les sept catégories vides affichent « Aucun document ».
    expect(find.text('Aucun document'), findsNWidgets(8));
    expect(find.text('Identité'), findsOneWidget);
    expect(find.text('Autres'), findsOneWidget);
    expect(find.text('Noter ma clé'), findsOneWidget);
    expect(env.paths.databaseFile.existsSync(), isTrue);
    expect(env.paths.recoverySlotFile.existsSync(), isTrue);

    // Noter la clé : affichage unique, confirmation, le rappel disparaît.
    await tester.tap(find.text('Noter ma clé'));
    await settle(tester, rounds: 10);
    expect(find.text('Votre clé de récupération'), findsOneWidget);
    final done = find.widgetWithText(FilledButton, 'Terminé');
    expect(tester.widget<FilledButton>(done).onPressed, isNull);
    await tester.tap(find.text('J\'ai conservé ma clé en lieu sûr'));
    await tester.pump();
    await tester.tap(done);
    await settle(tester, rounds: 10);
    expect(find.text('Noter ma clé'), findsNothing);

    // Verrouillage : la base est fermée et la clé effacée.
    final container = ProviderScope.containerOf(
      tester.element(find.text('Identité')),
    );
    final unlockedSession = (container.read(vaultControllerProvider) as VaultUnlocked).session;
    await tester.tap(find.byTooltip('Verrouiller'));
    await settle(tester);
    expect(find.text('Saisissez votre code'), findsOneWidget);
    expect(unlockedSession.isClosed, isTrue);
    expect(container.read(vaultControllerProvider), isA<VaultLocked>());

    // Mauvais code : message, puis bon code : retour au tableau de bord.
    await typePin(tester, '731906');
    await tester.tap(find.text('Confirmer'));
    await settle(tester);
    expect(find.textContaining('Code incorrect'), findsOneWidget);
    await typePin(tester, '204915');
    await tester.tap(find.text('Confirmer'));
    await settle(tester, rounds: 40);
    expect(find.text('Identité'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('code trop simple refusé, codes différents refusés', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(testApp(env));
    await settle(tester);
    await tester.tap(find.text('Passer'));
    await settle(tester, rounds: 5);

    await typePin(tester, '123456');
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(find.text('Ce code est trop simple. Choisissez-en un autre.'), findsOneWidget);

    await typePin(tester, '204915');
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await typePin(tester, '204916');
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(find.text('Les deux codes ne sont pas identiques. Recommencez.'), findsOneWidget);
    expect(find.text('Choisissez votre code'), findsOneWidget);
    await teardownApp(tester);
  });
}
