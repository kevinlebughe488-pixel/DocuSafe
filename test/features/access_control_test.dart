import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/lock/vault_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Tests de sécurité du cahier des charges (§10) : accès sans
/// authentification et verrouillage automatique (docs/04-securite.md §10).
void main() {
  late TestEnvironment env;
  var now = DateTime(2026, 11, 15, 10);

  setUp(() async {
    env = await TestEnvironment.create();
    now = DateTime(2026, 11, 15, 10);
  });
  tearDown(() => env.dispose());

  const protected = [
    Routes.home,
    Routes.documents,
    Routes.search,
    Routes.deadlines,
    Routes.settings,
    Routes.settingsSecurity,
    Routes.settingsBackup,
    Routes.settingsStorage,
    Routes.categories,
    '/documents/un-identifiant',
    '/documents/un-identifiant/view',
  ];

  Future<ProviderContainer> start(WidgetTester tester, {bool vault = true}) async {
    usePhoneSize(tester);
    if (vault) {
      await tester.runAsync(() async {
        final service = ProviderContainer(overrides: env.overrides()).read(vaultServiceProvider);
        final session = await service.commitSetup(await service.prepareSetup('204915'));
        await session.close();
      });
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          clockProvider.overrideWithValue(() => now),
        ],
        child: testAppChild(),
      ),
    );
    await settle(tester, rounds: 8);
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  }

  Future<void> unlock(WidgetTester tester, ProviderContainer container) async {
    await tester.runAsync(
      () => container.read(vaultControllerProvider.notifier).unlockWithPin('204915'),
    );
    await settle(tester, rounds: 8);
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
  }

  /// Fait passer l'application en arrière-plan, puis au premier plan.
  Future<void> background(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await settle(tester, rounds: 6);
  }

  Future<void> foreground(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settle(tester, rounds: 6);
  }

  testWidgets('sans coffre : toute adresse protégée ramène à la bienvenue', (tester) async {
    final container = await start(tester, vault: false);
    for (final location in protected) {
      container.read(routerProvider).go(location);
      await settle(tester, rounds: 3);
      expect(find.text('Bienvenue dans DocuSafe'), findsOneWidget, reason: location);
    }
    await teardownApp(tester);
  });

  testWidgets('coffre verrouillé : aucune adresse protégée ne s\'affiche', (tester) async {
    final container = await start(tester);
    expect(find.text('Saisissez votre code'), findsOneWidget);
    for (final location in protected) {
      container.read(routerProvider).go(location);
      await settle(tester, rounds: 3);
      expect(find.text('Saisissez votre code'), findsOneWidget, reason: location);
      expect(container.read(vaultControllerProvider), isA<VaultLocked>());
    }
    // La base est fermée : aucune session n'existe.
    expect(container.read(vaultControllerProvider.notifier).session, isNull);
    await teardownApp(tester);
  });

  testWidgets('inactivité : verrouillage après le délai, repoussé par un toucher', (
    tester,
  ) async {
    final container = await start(tester);
    await unlock(tester, container);
    final controller = container.read(vaultControllerProvider.notifier);
    // Le minuteur est relancé dans le temps simulé du test.
    controller.touch();

    await tester.pump(const Duration(seconds: 90));
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    // Un toucher relance le compte à rebours de deux minutes.
    await tester.tapAt(const Offset(180, 300));
    await tester.pump(const Duration(seconds: 90));
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());

    await tester.pump(const Duration(seconds: 31));
    await settle(tester, rounds: 8);
    final state = container.read(vaultControllerProvider);
    expect(state, isA<VaultLocked>());
    expect((state as VaultLocked).reason, LockReason.inactivity);
    expect(find.text('Saisissez votre code'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('arrière-plan : verrouillage immédiat', (tester) async {
    final container = await start(tester);
    await unlock(tester, container);
    await background(tester);
    final state = container.read(vaultControllerProvider);
    expect(state, isA<VaultLocked>());
    expect((state as VaultLocked).reason, LockReason.background);
    await foreground(tester);
    expect(find.text('Saisissez votre code'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('fenêtre du système ouverte par DocuSafe : tolérance de cinq minutes', (
    tester,
  ) async {
    final container = await start(tester);
    await unlock(tester, container);
    final controller = container.read(vaultControllerProvider.notifier);

    // Retour avant cinq minutes : le coffre reste ouvert.
    controller.beginExternalOperation();
    await background(tester);
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    now = now.add(const Duration(minutes: 4));
    await foreground(tester);
    controller.endExternalOperation();
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());

    // Retour après cinq minutes : verrouillé.
    controller.beginExternalOperation();
    await background(tester);
    now = now.add(const Duration(minutes: 6));
    await foreground(tester);
    controller.endExternalOperation();
    expect(container.read(vaultControllerProvider), isA<VaultLocked>());
    await teardownApp(tester);
  });
}
