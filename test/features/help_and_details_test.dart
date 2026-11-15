import 'dart:io';

import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/database/default_categories.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/entitlements/entitlement_service.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/features/settings/presentation/help/help_screen.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Assistance (§3.13), date de modification sur la fiche (§3.6), droits
/// d'utilisation (§8).
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  test('MVP gratuit : aucune fonction Premium débloquée', () {
    const service = FreeEntitlementService();
    expect(service.plan, Plan.free);
    for (final feature in PremiumFeature.values) {
      expect(service.isUnlocked(feature), isFalse);
    }
  });

  testWidgets('aide : réponses sans Internet, contact seulement s\'il existe', (tester) async {
    usePhoneSize(tester);
    // Les traductions de Material se chargent en quelques images.
    Future<void> show(Widget w) async {
      await tester.pumpWidget(wrap(w));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await show(const HelpScreen());
    expect(find.text("J'ai oublié mon code"), findsOneWidget);
    expect(find.text("Écrire à l'assistance", skipOffstage: false), findsNothing);
    await tester.tap(find.text("J'ai oublié mon code"));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Code oublié ?'), findsOneWidget);

    await show(const HelpScreen(supportEmail: 'aide@exemple.fr'));
    await tester.scrollUntilVisible(find.text("Écrire à l'assistance"), 300);
    expect(find.text("Écrire à l'assistance"), findsOneWidget);
    expect(find.text('aide@exemple.fr'), findsOneWidget);
  });

  testWidgets('paramètres → aide ; fiche : « Modifié le » après une modification', (
    tester,
  ) async {
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
        title: 'Bail',
        categoryId: DefaultCategory.othersId,
      ));
      id = row.id;
    });

    container.read(routerProvider).go(Routes.settings);
    await settle(tester, rounds: 8);
    await tester.scrollUntilVisible(find.text('Aide et assistance'), 200);
    await tester.tap(find.text('Aide et assistance'));
    await settle(tester, rounds: 8);
    expect(find.text('Je change de téléphone'), findsOneWidget);

    // Fiche juste après l'ajout : pas de date de modification.
    container.read(routerProvider).go(Routes.document(id));
    await settle(tester, rounds: 8);
    expect(find.text('Ajouté le'), findsOneWidget);
    expect(find.text('Modifié le'), findsNothing);

    // Modifié deux jours plus tard.
    await tester.runAsync(() async {
      final db = container.read(databaseProvider);
      await db.customUpdate(
        'UPDATE documents SET updated_at = ? WHERE id = ?',
        variables: [
          Variable<DateTime>(DateTime.now().add(const Duration(days: 2))),
          Variable<String>(id),
        ],
        updates: {db.documents},
      );
    });
    await settle(tester, rounds: 8);
    expect(find.text('Modifié le'), findsOneWidget);
    await teardownApp(tester);
  });
}
