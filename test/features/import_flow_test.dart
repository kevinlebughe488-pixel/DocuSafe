import 'dart:io';

import 'package:docusafe/core/platform/file_picker_service.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/lock/vault_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Parcours d'importation complet avec un sélecteur simulé
/// (docs/05-parcours-utilisateurs.md §4), puis fiche, favori, suppression.
void main() {
  late TestEnvironment env;
  late FakeFilePickerService picker;
  late Directory picked;

  setUp(() async {
    env = await TestEnvironment.create();
    picked = await Directory('${env.root.path}/picked').create();
    picker = FakeFilePickerService();
  });

  tearDown(() => env.dispose());

  Future<void> createVaultAndUnlock(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          filePickerServiceProvider.overrideWithValue(picker),
          thumbnailServiceProvider.overrideWithValue(const ImageOnlyThumbnailService()),
        ],
        child: testAppChild(),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Passer'));
    await settle(tester, rounds: 5);
    await typePin(tester, '204915');
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await typePin(tester, '204915');
    await tester.tap(find.text('Continuer'));
    await settle(tester, rounds: 40);
    expect(find.text('Votre coffre est vide'), findsOneWidget);
  }

  testWidgets('importer un PDF et une image, puis consulter la fiche', (tester) async {
    usePhoneSize(tester);
    await createVaultAndUnlock(tester);

    // Le sélecteur « rend » deux fichiers de test et un fichier refusé.
    // (Entrées-sorties réelles : hors du temps simulé du test.)
    await tester.runAsync(() async {
      final pdf = await File('test/fixtures/simple.pdf').copy('${picked.path}/Contrat de bail.pdf');
      final png = await File('test/fixtures/rouge.png').copy('${picked.path}/IMG_2041.png');
      final txt = await File('test/fixtures/notes.txt').copy('${picked.path}/notes.docx');
      picker.documents = [
        PickedFile(file: pdf, displayName: 'Contrat de bail.pdf'),
        PickedFile(file: png, displayName: 'IMG_2041.png'),
        PickedFile(file: txt, displayName: 'notes.docx'),
      ];
    });

    // Le bouton est sous la ligne de flottaison : on fait défiler l'accueil.
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await settle(tester, rounds: 3);
    await tester.tap(find.text('Importer un fichier'));
    await settle(tester, rounds: 40);
    expect(find.text('3 fichiers sélectionnés'), findsOneWidget);
    expect(find.text('Format non pris en charge'), findsOneWidget);
    expect(find.text('Continuer avec 2 fichiers'), findsOneWidget);
    // Les copies temporaires sont dans le dossier privé de DocuSafe.
    expect(env.paths.secureTempDir.listSync().length, 3);

    await tester.tap(find.text('Continuer avec 2 fichiers'));
    await settle(tester, rounds: 10);
    expect(find.text('Informations'), findsOneWidget);
    expect(find.textContaining('Catégorie commune'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Contrat de bail'), findsOneWidget);

    await tester.tap(find.text('Enregistrer dans le coffre'));
    await settle(tester, rounds: 60);
    expect(find.textContaining('2 documents enregistrés'), findsOneWidget);
    expect(find.text('Documents'), findsWidgets);
    expect(find.text('Contrat de bail'), findsOneWidget);
    expect(find.text('IMG_2041'), findsOneWidget);
    // Plus aucun fichier en clair.
    expect(env.paths.secureTempDir.listSync(), isEmpty);
    expect(env.paths.filesDir.listSync(recursive: true).whereType<File>().length, 2);

    // Fiche, favori, puis suppression.
    await tester.tap(find.text('Contrat de bail'));
    await settle(tester, rounds: 10);
    expect(find.text('Ouvrir'), findsOneWidget);
    expect(find.text('Autres'), findsOneWidget);
    await tester.tap(find.byTooltip('Ajouter aux favoris'));
    await settle(tester, rounds: 5);
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await settle(tester, rounds: 5);
    await tester.tap(find.text('Supprimer').last);
    await settle(tester, rounds: 5);
    expect(find.text('Supprimer ce document ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer définitivement'));
    await settle(tester);
    expect(find.text('Document supprimé.'), findsOneWidget);
    expect(find.text('Contrat de bail'), findsNothing);
    expect(env.paths.filesDir.listSync(recursive: true).whereType<File>().length, 1);

    // Le coffre reste cohérent après verrouillage.
    final container = ProviderScope.containerOf(tester.element(find.text('IMG_2041')));
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    await teardownApp(tester);
  });

  testWidgets('créer une catégorie, puis la supprimer', (tester) async {
    usePhoneSize(tester);
    await createVaultAndUnlock(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await settle(tester, rounds: 3);
    await tester.tap(find.text('Gérer'));
    await settle(tester, rounds: 5);
    expect(find.text('Nouvelle catégorie'), findsOneWidget);
    await tester.tap(find.text('Nouvelle catégorie'));
    await settle(tester, rounds: 5);
    await tester.enterText(find.byType(TextField), 'Voiture');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester, rounds: 12);
    expect(find.text('Catégorie enregistrée.'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Voiture'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Voiture'));
    await settle(tester, rounds: 5);
    await tester.tap(find.text('Supprimer la catégorie'));
    await settle(tester, rounds: 5);
    expect(find.text('Supprimer « Voiture » ?'), findsOneWidget);
    await tester.tap(find.text('Supprimer').last);
    await settle(tester, rounds: 12);
    // Le message bref précédent peut encore occuper l'écran : on vérifie la liste.
    expect(find.widgetWithText(ListTile, 'Voiture'), findsNothing);
    expect(find.text('Nouvelle catégorie'), findsOneWidget);
    await teardownApp(tester);
  });
}
