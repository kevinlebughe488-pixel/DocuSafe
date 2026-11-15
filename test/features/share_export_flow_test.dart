import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/documents/export_document.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Partager ou exporter (docs/05-parcours-utilisateurs.md §10).
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  /// Laisse le temps réel s'écouler (déchiffrement dans un isolate) jusqu'à
  /// ce que [done] soit vrai.
  Future<void> waitFor(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 50 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(done(), isTrue);
  }

  testWidgets('partage, export d\'un document, export de toutes les données', (
    tester,
  ) async {
    usePhoneSize(tester);
    await tester.runAsync(() async {
      final service = ProviderContainer(overrides: env.overrides())
          .read(vaultServiceProvider);
      final session = await service.commitSetup(
        await service.prepareSetup('204915'),
      );
      await session.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          thumbnailServiceProvider.overrideWithValue(
            const ImageOnlyThumbnailService(),
          ),
        ],
        child: testAppChild(),
      ),
    );
    await settle(tester, rounds: 8);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );

    late String id;
    await tester.runAsync(() async {
      await container
          .read(vaultControllerProvider.notifier)
          .unlockWithPin('204915');
      final temp = env.paths.secureTempDir..createSync(recursive: true);
      final f = await File('test/fixtures/simple.pdf')
          .copy('${temp.path}/bail.pdf');
      final ingest = container.read(ingestDocumentProvider);
      final check = await ingest.check(f) as FileAccepted;
      final row = await ingest(
        IngestRequest(
          source: f,
          fileName: 'bail.pdf',
          check: check,
          title: 'Bail',
          categoryId: DefaultCategory.othersId,
        ),
      );
      id = row.id;
    });
    final original = File('test/fixtures/simple.pdf').readAsBytesSync();
    container.read(routerProvider).go(Routes.document(id));
    await settle(tester, rounds: 8);

    // Partager : avertissement, puis Annuler → rien ne sort.
    await tester.tap(find.text('Partager'));
    await settle(tester);
    expect(find.text('Partager ce document ?'), findsOneWidget);
    expect(find.textContaining('ne sera plus protégé'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await settle(tester);
    expect(env.shares.shared, isEmpty);

    // Partager → Continuer : la feuille reçoit le fichier en clair.
    await tester.tap(find.text('Partager'));
    await settle(tester);
    await tester.tap(find.text('Continuer'));
    await waitFor(tester, () => env.shares.shared.isNotEmpty);
    expect(env.shares.shared.single.$1, 'Bail.pdf');
    expect(env.shares.shared.single.$2, original);

    // Exporter : enregistrement à l'emplacement choisi.
    await tester.tap(find.text('Exporter'));
    await settle(tester);
    expect(find.text('Exporter ce document ?'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await waitFor(tester, () => env.shares.saved.isNotEmpty);
    expect(env.shares.saved.single.$1, 'Bail.pdf');
    expect(env.shares.saved.single.$2, original);
    await settle(tester);
    expect(find.text('Copie enregistrée.'), findsOneWidget);

    // Paramètres → Exporter mes données : archive ZIP.
    container.read(routerProvider).go(Routes.settings);
    await settle(tester, rounds: 8);
    await tester.tap(find.text('Exporter mes données'));
    await settle(tester);
    expect(find.text('Exporter tous vos documents ?'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await waitFor(tester, () => env.shares.saved.length == 2);
    final archive = env.shares.saved.last;
    expect(archive.$1, startsWith('DocSafe-export-'));
    final zip = ZipDecoder().decodeBytes(archive.$2);
    expect(zip.files.single.name, endsWith('/Bail.pdf'));
    expect(zip.files.single.content, original);

    // Le verrouillage purge la copie partagée.
    await tester.runAsync(
      () => container.read(vaultControllerProvider.notifier).lock(),
    );
    await settle(tester);
    expect(
      Directory('${env.paths.secureTempDir.path}/share').existsSync(),
      isFalse,
    );
    DocumentExporter.cancelPendingDeletes();
    await teardownApp(tester);
  });
}
