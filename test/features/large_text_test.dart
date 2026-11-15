import 'dart:io';

import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Accessibilité (cahier des charges §6.3) : avec la plus grande taille de
/// police d'Android (200 %), aucun écran principal ne déborde. Un débordement
/// lève une erreur qui fait échouer ce test.
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  void useLargeText(WidgetTester tester) {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('accueil sans coffre et choix du code, police à 200 %', (tester) async {
    usePhoneSize(tester);
    useLargeText(tester);
    await tester.pumpWidget(testApp(env));
    await settle(tester);
    expect(find.text('Bienvenue dans DocSafe'), findsOneWidget);
    await tester.tap(find.text('Passer'));
    await settle(tester, rounds: 5);
    expect(find.text('Choisissez votre code'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('écrans du coffre ouvert, police à 200 %', (tester) async {
    usePhoneSize(tester);
    useLargeText(tester);
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
    expect(find.text('Saisissez votre code'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    late String id;
    await tester.runAsync(() async {
      await container.read(vaultControllerProvider.notifier).unlockWithPin('204915');
      final temp = env.paths.secureTempDir..createSync(recursive: true);
      final f = await File('test/fixtures/simple.pdf').copy('${temp.path}/bail.pdf');
      final ingest = container.read(ingestDocumentProvider);
      final check = await ingest.check(f) as FileAccepted;
      final row = await ingest(IngestRequest(
        source: f,
        fileName: 'bail.pdf',
        check: check,
        title: 'Contrat de location de l’appartement',
        categoryId: DefaultCategory.othersId,
        expirationDate: DateOnly.today().addDays(20),
      ));
      id = row.id;
    });
    await settle(tester, rounds: 8);

    final router = container.read(routerProvider);
    for (final location in [
      Routes.home,
      Routes.documents,
      Routes.document(id),
      Routes.search,
      Routes.deadlines,
      Routes.settings,
      Routes.settingsSecurity,
      Routes.settingsNotifications,
      Routes.settingsStorage,
      Routes.settingsBackup,
      Routes.settingsHelp,
      Routes.categories,
    ]) {
      router.go(location);
      await settle(tester, rounds: 6);
    }
    await teardownApp(tester);
  });
}
