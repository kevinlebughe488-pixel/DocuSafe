import 'package:docusafe/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// Tests d'intégration (cahier des charges §10) : la vraie application, sur
/// un émulateur ou un téléphone Android, avec le vrai stockage sécurisé, la
/// vraie base chiffrée et le vrai calcul du code (Argon2id).
///
/// Lancement : flutter test integration_test (appareil ou émulateur branché).
/// Dans GitHub : recette « Tests d'intégration ». Le téléphone doit partir
/// d'une installation neuve (aucun coffre).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Attend qu'un élément apparaisse (temps réel, au plus [seconds]).
  Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 60}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    fail('Introuvable après $seconds s : $finder');
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.widgetWithText(InkWell, digit).last);
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('créer le coffre, verrouiller, rouvrir, profil, aide', (tester) async {
    await app.main();
    await waitFor(tester, find.text('Bienvenue dans DocSafe'));

    // Création du coffre : code choisi puis confirmé.
    await tester.tap(find.text('Passer'));
    await waitFor(tester, find.text('Choisissez votre code'));
    await typePin(tester, '204915');
    await tester.tap(find.text('Continuer'));
    await waitFor(tester, find.text('Confirmez votre code'));
    await typePin(tester, '204915');
    await tester.tap(find.text('Continuer'));
    // Biométrie proposée seulement si le téléphone en a une.
    final ready = find.text('Votre coffre est vide');
    final biometric = find.text('Plus tard');
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (ready.evaluate().isEmpty && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (biometric.evaluate().isNotEmpty) {
        await tester.tap(biometric);
      }
    }
    expect(ready, findsOneWidget);

    // Mauvais code refusé, bon code accepté.
    await tester.tap(find.byTooltip('Verrouiller'));
    await waitFor(tester, find.text('Saisissez votre code'));
    await typePin(tester, '111999');
    await tester.tap(find.text('Confirmer'));
    await waitFor(tester, find.textContaining('Code incorrect'));
    await typePin(tester, '204915');
    await tester.tap(find.text('Confirmer'));
    await waitFor(tester, ready);

    // Profil local, puis salutation sur l'accueil.
    await tester.tap(find.text('Paramètres').last);
    await waitFor(tester, find.text('Profil local'));
    await tester.tap(find.text('Profil local'));
    await waitFor(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.tap(find.text('Enregistrer'));
    await waitFor(tester, find.text('Awa'));

    // Aide hors ligne.
    await tester.scrollUntilVisible(find.text('Aide et assistance'), 200);
    await tester.tap(find.text('Aide et assistance'));
    await waitFor(tester, find.text("J'ai oublié mon code"));
    // Bouton retour de la barre (libellé « Retour »).
    await tester.tap(find.byTooltip('Retour'));
    await waitFor(tester, find.text('Profil local'));

    await tester.tap(find.text('Accueil').last);
    await waitFor(tester, find.text('Bonjour Awa'));
  });
}
