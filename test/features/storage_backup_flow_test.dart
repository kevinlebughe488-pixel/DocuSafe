import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/database/daos/settings_dao.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Écran Stockage (19) et création d'une sauvegarde (19b).
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 50 && !done(); i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(done(), isTrue);
  }

  testWidgets('stockage par catégorie, nettoyage, sauvegarde', (tester) async {
    usePhoneSize(tester);
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
    await tester.runAsync(() async {
      await container.read(vaultControllerProvider.notifier).unlockWithPin('204915');
      final temp = env.paths.secureTempDir..createSync(recursive: true);
      final f = await File('test/fixtures/simple.pdf').copy('${temp.path}/bail.pdf');
      final ingest = container.read(ingestDocumentProvider);
      final check = await ingest.check(f) as FileAccepted;
      await ingest(IngestRequest(
        source: f,
        fileName: 'bail.pdf',
        check: check,
        title: 'Bail',
        categoryId: DefaultCategory.othersId,
      ));
      // Un fichier temporaire oublié.
      File('${temp.path}/oubli.tmp').writeAsBytesSync(List.filled(2048, 1));
    });

    container.read(routerProvider).go(Routes.settings);
    await settle(tester, rounds: 8);
    await tester.tap(find.text('Stockage'));
    await settle(tester, rounds: 10);
    expect(find.text('1 document chiffré · 8 Go libres sur le téléphone'), findsOneWidget);
    expect(find.text('Autres'), findsOneWidget);
    expect(find.text('2 ko en attente'), findsOneWidget);
    await tester.tap(find.text('Nettoyer'));
    await settle(tester, rounds: 10);
    expect(find.text('Aucun fichier en attente'), findsOneWidget);
    container.read(routerProvider).pop();
    await settle(tester, rounds: 6);

    // Sauvegarde : la clé de récupération doit d'abord être notée.
    await tester.tap(find.text('Sauvegarde et synchronisation'));
    await settle(tester, rounds: 8);
    expect(find.text('Aucune sauvegarde pour l\'instant'), findsOneWidget);
    expect(find.text('Non disponible'), findsOneWidget);
    await tester.tap(find.text('Créer une sauvegarde'));
    await settle(tester);
    expect(find.text('Notez d\'abord votre clé'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await settle(tester);

    await tester.runAsync(
      () => container
          .read(databaseProvider)
          .settingsDao
          .writeConfig(VaultConfigKeys.recoveryKeyConfirmed, true),
    );
    await tester.tap(find.text('Créer une sauvegarde'));
    await waitFor(tester, () => env.shares.saved.isNotEmpty);
    final (name, bytes) = env.shares.saved.single;
    expect(name, endsWith('.docusafe'));
    final zip = ZipDecoder().decodeBytes(bytes);
    expect(zip.files.map((f) => f.name), contains('manifest.json'));
    expect(zip.files.where((f) => f.name.startsWith('files/')).length, 1);
    await settle(tester, rounds: 10);
    expect(find.textContaining('Dernière :'), findsOneWidget);
    // Le fichier préparé a été supprimé.
    expect(Directory('${env.paths.secureTempDir.path}/backup').listSync(), isEmpty);
    await teardownApp(tester);
  });
}
