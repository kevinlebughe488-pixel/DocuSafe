import 'dart:io';

import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Échéances et rappels (docs/05-parcours-utilisateurs.md §9).
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  testWidgets('onglet Échéances, rappels d\'un document, réglages, notification touchée', (
    tester,
  ) async {
    usePhoneSize(tester);
    // Coffre créé hors de l'interface, puis ouvert par le contrôleur : la
    // base vit alors hors du temps simulé du test (même schéma que les
    // captures d'écran).
    await tester.runAsync(() async {
      final service = ProviderContainer(overrides: env.overrides()).read(vaultServiceProvider);
      final session = await service.commitSetup(await service.prepareSetup('204915'));
      await session.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          thumbnailServiceProvider.overrideWithValue(const ImageOnlyThumbnailService()),
        ],
        child: testAppChild(),
      ),
    );
    await settle(tester, rounds: 8);
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

    // Un document qui expire dans 12 jours : 90 et 30 jours avant sont passés.
    late String id;
    await tester.runAsync(() async {
      await container.read(vaultControllerProvider.notifier).unlockWithPin('204915');
      final temp = env.paths.secureTempDir..createSync(recursive: true);
      final f = await File('test/fixtures/simple.pdf').copy('${temp.path}/visa.pdf');
      final ingest = container.read(ingestDocumentProvider);
      final check = await ingest.check(f) as FileAccepted;
      final row = await ingest(IngestRequest(
        source: f,
        fileName: 'visa.pdf',
        check: check,
        title: 'Visa Schengen',
        categoryId: DefaultCategory.othersId,
        expirationDate: DateOnly.today().addDays(12),
      ));
      id = row.id;
      await container.read(reminderServiceProvider).syncDocument(id);
    });
    await settle(tester, rounds: 10);
    expect(env.notifications.scheduled.length, 2);
    expect(env.notifications.scheduled.first.title, 'Échéance dans 7 jours');

    // L'accueil montre l'échéance ; l'onglet la classe dans les 30 jours.
    expect(find.text('Échéances à venir'), findsOneWidget);
    await tester.tap(find.text('Échéances').last);
    await settle(tester, rounds: 8);
    expect(find.text('Dans les 30 jours'), findsOneWidget);
    expect(find.text('J-12'), findsOneWidget);
    expect(find.text('30 jours · 1'), findsOneWidget);

    // Fiche → ligne Expiration → rappels.
    await tester.tap(find.text('Visa Schengen'));
    await settle(tester, rounds: 8);
    await tester.tap(find.text('Expiration'));
    await settle(tester, rounds: 8);
    expect(find.text('Rappels'), findsWidgets);
    expect(find.text('90 jours avant'), findsOneWidget);
    expect(find.text('Le jour même'), findsOneWidget);
    expect(find.textContaining('passé'), findsNWidgets(2));

    await tester.tap(find.text('7 jours avant'));
    await settle(tester, rounds: 8);
    expect(env.notifications.scheduled.length, 1);

    // Notification touchée : la fiche s'ouvre.
    container.read(routerProvider).pop();
    await settle(tester, rounds: 5);
    container.read(routerProvider).pop();
    await settle(tester, rounds: 5);
    env.notifications.tap(id);
    await settle(tester, rounds: 8);
    expect(find.text('Visa Schengen'), findsWidgets);
    expect(find.text('Ouvrir'), findsOneWidget);
    container.read(routerProvider).pop();
    await settle(tester, rounds: 5);

    // Réglages : couper les rappels vide la programmation.
    await tester.tap(find.byTooltip('Notifications'));
    await settle(tester, rounds: 8);
    expect(find.text('Échéance dans 7 jours'), findsOneWidget);
    await tester.tap(find.text('Rappels d\'échéance'));
    await settle(tester, rounds: 8);
    expect(env.notifications.scheduled, isEmpty);
    await teardownApp(tester);
  });
}
