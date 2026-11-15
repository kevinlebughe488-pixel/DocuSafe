import 'dart:io';

import 'package:docusafe/core/platform/file_picker_service.dart';
import 'package:docusafe/core/platform/scanner_service.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Parcours du scanner (docs/05-parcours-utilisateurs.md §3) puis recherche
/// (§7), avec un scanner simulé qui rend de vraies images.
void main() {
  late TestEnvironment env;
  late FakeScannerService scanner;
  late Directory scans;

  setUp(() async {
    env = await TestEnvironment.create();
    scanner = FakeScannerService();
    scans = await Directory('${env.root.path}/scanner_cache').create();
  });

  tearDown(() => env.dispose());

  Future<void> start(WidgetTester tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          scannerServiceProvider.overrideWithValue(scanner),
          filePickerServiceProvider.overrideWithValue(FakeFilePickerService()),
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
  }

  /// Le scanner « rend » [count] pages, écrites dans son propre dossier.
  Future<void> preparePages(WidgetTester tester, int count) async {
    await tester.runAsync(() async {
      scanner.pages = [
        for (var i = 0; i < count; i++)
          await File('test/fixtures/rouge.png').copy('${scans.path}/page_${DateTime.now().microsecondsSinceEpoch}_$i.png'),
      ];
    });
  }

  testWidgets('numériser deux pages, en retirer une, en ajouter, enregistrer, rechercher', (
    tester,
  ) async {
    await start(tester);

    await preparePages(tester, 2);
    await tester.tap(find.text('Scanner').last);
    await settle(tester, rounds: 5);
    expect(find.text('Numériser un document'), findsOneWidget);
    await tester.tap(find.text('Numériser'));
    await settle(tester, rounds: 30);

    // Aperçu : deux pages ; les images du scanner ont été déplacées.
    expect(find.text('Aperçu du scan'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);
    expect(scanner.cleanCalls, 1);
    expect(scans.listSync(), isEmpty);

    await tester.tap(find.byTooltip('Retirer la page 2'));
    await settle(tester, rounds: 5);
    expect(find.text('Page 2'), findsNothing);

    await preparePages(tester, 1);
    await tester.tap(find.text('Ajouter des pages'));
    await settle(tester, rounds: 30);
    expect(find.text('Page 2'), findsOneWidget);
    expect(scanner.scanCalls, 2);

    // Continuer : PDF assemblé, formulaire pré-rempli.
    await tester.tap(find.text('Continuer'));
    await settle(tester, rounds: 60);
    expect(find.text('Informations'), findsOneWidget);
    // Titre proposé dans le champ « Nom » et nom du fichier sous l'aperçu.
    expect(find.textContaining('Scan du '), findsNWidgets(2));
    expect(find.textContaining('2 pages · PDF'), findsOneWidget);

    await tester.tap(find.text('Enregistrer dans le coffre'));
    await settle(tester, rounds: 60);
    expect(find.textContaining('1 document enregistré'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListTile), matching: find.textContaining('Scan du ')),
      findsOneWidget,
    );

    // Plus aucun fichier en clair ; un document et sa miniature chiffrés.
    expect(env.paths.secureTempDir.listSync(), isEmpty);
    expect(env.paths.filesDir.listSync(recursive: true).whereType<File>().length, 1);
    final thumbs = env.paths.thumbsDir.listSync(recursive: true).whereType<File>().toList();
    expect(thumbs.length, 1);
    expect(thumbs.single.path.endsWith('.dst'), isTrue);

    // Recherche : sans accent ni majuscule, résultat mis en évidence.
    await tester.tap(find.byTooltip('Rechercher un document'));
    await settle(tester, rounds: 5);
    expect(find.text('Rechercher dans le coffre'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'SCAN');
    await settle(tester, rounds: 10);
    expect(find.text('1 résultat'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'passeport');
    await settle(tester, rounds: 10);
    expect(find.text('Aucun résultat'), findsOneWidget);

    // Filtre seul : favoris (aucun) puis format PDF.
    await tester.enterText(find.byType(TextField), '');
    await settle(tester, rounds: 5);
    // La puce est au bord de l'écran : on fait défiler la barre de filtres.
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Favoris'));
    await settle(tester, rounds: 3);
    await tester.tap(find.widgetWithText(FilterChip, 'Favoris'));
    await settle(tester, rounds: 10);
    expect(find.text('Aucun résultat'), findsOneWidget);
    expect(find.text('Effacer les filtres'), findsOneWidget);
    await tester.tap(find.text('Effacer les filtres'));
    await settle(tester, rounds: 10);
    expect(find.text('Rechercher dans le coffre'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('abandonner un scan efface les pages', (tester) async {
    await start(tester);
    await preparePages(tester, 1);
    await tester.tap(find.text('Scanner').last);
    await settle(tester, rounds: 5);
    await tester.tap(find.text('Numériser'));
    await settle(tester, rounds: 30);
    expect(env.paths.secureTempDir.listSync().length, 1);
    await tester.tap(find.byTooltip('Fermer'));
    await settle(tester, rounds: 5);
    expect(find.text('Abandonner ce scan ?'), findsOneWidget);
    await tester.tap(find.text('Abandonner'));
    await settle(tester, rounds: 10);
    expect(find.text('Numériser un document'), findsOneWidget);
    expect(env.paths.secureTempDir.listSync(), isEmpty);
    await teardownApp(tester);
  });
}
