import 'dart:io';

import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/lock/vault_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Écrans sans test jusqu'ici : code oublié (clé de récupération), lecture
/// d'une image, modification d'un document, textes légaux.
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  Future<ProviderContainer> start(WidgetTester tester, {void Function(String)? onKey}) async {
    usePhoneSize(tester);
    await tester.runAsync(() async {
      final service = ProviderContainer(overrides: env.overrides()).read(vaultServiceProvider);
      final pending = await service.prepareSetup('204915');
      onKey?.call(pending.recoveryKey.display);
      final session = await service.commitSetup(pending);
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
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  }

  testWidgets('code oublié : clé de récupération puis nouveau code', (tester) async {
    late String recoveryKey;
    final container = await start(tester, onKey: (k) => recoveryKey = k);
    expect(find.text('Coffre verrouillé'), findsOneWidget);
    await tester.tap(find.text('Code oublié ?'));
    await settle(tester, rounds: 6);
    expect(find.text('Code oublié'), findsOneWidget);
    await tester.enterText(find.byType(TextField), recoveryKey);
    await tester.pump();
    await tester.tap(find.text('Vérifier la clé'));
    await settle(tester, rounds: 30);
    expect(find.text('Choisissez un nouveau code'), findsWidgets);
    await typePin(tester, '813572');
    await tester.pump();
    await typePin(tester, '813572');
    await settle(tester, rounds: 30);
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());

    // Le nouveau code ouvre le coffre, l'ancien non.
    await tester.runAsync(() async {
      final controller = container.read(vaultControllerProvider.notifier);
      await controller.lock();
      await controller.unlockWithPin('813572');
    });
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    await teardownApp(tester);
  });

  testWidgets('lire une image, modifier un document, textes légaux', (tester) async {
    final container = await start(tester);
    late String id;
    await tester.runAsync(() async {
      await container.read(vaultControllerProvider.notifier).unlockWithPin('204915');
      final temp = env.paths.secureTempDir..createSync(recursive: true);
      final f = await File('test/fixtures/rouge.png').copy('${temp.path}/photo.png');
      final ingest = container.read(ingestDocumentProvider);
      final check = await ingest.check(f) as FileAccepted;
      final row = await ingest(IngestRequest(
        source: f,
        fileName: 'photo.png',
        check: check,
        title: 'Carte vitale',
        categoryId: DefaultCategory.othersId,
      ));
      id = row.id;
    });
    final router = container.read(routerProvider);

    // Lecture : le document est déchiffré et affiché.
    router.go(Routes.documentView(id));
    await settle(tester);
    expect(find.text('Carte vitale'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // Modification du nom.
    router.go(Routes.documentEdit(id));
    await settle(tester, rounds: 10);
    await tester.enterText(find.byType(TextField).first, 'Carte Vitale 2026');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester, rounds: 10);
    expect(find.text('Modifications enregistrées.'), findsOneWidget);
    final doc = await tester.runAsync(
      () => container.read(databaseProvider).documentsDao.getById(id),
    );
    expect(doc!.title, 'Carte Vitale 2026');

    // Textes légaux, lisibles sans coffre ouvert.
    router.go(Routes.legalPrivacy);
    await settle(tester, rounds: 10);
    expect(find.textContaining('Politique de confidentialité'), findsWidgets);
    await teardownApp(tester);
  });
}
