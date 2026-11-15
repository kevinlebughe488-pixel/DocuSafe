import 'dart:convert';

import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/platform/scanner_service.dart';
import 'package:docusafe/core/platform/system_settings_service.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/lock/vault_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Retours d'essai sur téléphone du 15/11/2026 : code de six chiffres validé
/// tout seul, écran « Coffre verrouillé », anciens coffres, autorisations,
/// scanner refusé.
void main() {
  late TestEnvironment env;

  setUp(() async {
    env = await TestEnvironment.create();
  });

  tearDown(() => env.dispose());

  /// Coffre créé hors de l'interface. [legacy] : serrure d'un coffre créé
  /// avant le 15/11/2026, sans la longueur du code.
  Future<void> createVault(WidgetTester tester, {bool legacy = false}) async {
    await tester.runAsync(() async {
      final service = ProviderContainer(overrides: env.overrides()).read(vaultServiceProvider);
      final session = await service.commitSetup(await service.prepareSetup('204915'));
      await session.close();
      if (legacy) {
        final raw = (await env.store.read(SecureStoreKeys.pinSlot))!;
        final slot = jsonDecode(raw) as Map<String, Object?>..remove('len');
        await env.store.write(SecureStoreKeys.pinSlot, jsonEncode(slot));
      }
    });
  }

  Future<ProviderContainer> startApp(
    WidgetTester tester, {
    FakeScannerService? scanner,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          thumbnailServiceProvider.overrideWithValue(const ImageOnlyThumbnailService()),
          if (scanner != null) scannerServiceProvider.overrideWithValue(scanner),
        ],
        child: testAppChild(),
      ),
    );
    await settle(tester, rounds: 8);
    return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
  }

  Future<ProviderContainer> startUnlocked(
    WidgetTester tester, {
    FakeScannerService? scanner,
  }) async {
    await createVault(tester);
    final container = await startApp(tester, scanner: scanner);
    await tester.runAsync(
      () => container.read(vaultControllerProvider.notifier).unlockWithPin('204915'),
    );
    await settle(tester, rounds: 4);
    return container;
  }

  testWidgets('« Coffre verrouillé » : six chiffres, ouverture sans bouton', (tester) async {
    usePhoneSize(tester);
    await createVault(tester);
    final container = await startApp(tester);
    expect(find.text('Coffre verrouillé'), findsOneWidget);
    expect(find.text("Saisissez votre code pour l'ouvrir."), findsOneWidget);
    expect(find.text('Confirmer'), findsNothing);

    await typePin(tester, '204915');
    await settle(tester);
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    await teardownApp(tester);
  });

  testWidgets('ancien coffre (code sans longueur) : bouton Confirmer', (tester) async {
    usePhoneSize(tester);
    await createVault(tester, legacy: true);
    final container = await startApp(tester);
    expect(find.text('Coffre verrouillé'), findsOneWidget);

    await typePin(tester, '204915');
    await settle(tester, rounds: 4);
    expect(container.read(vaultControllerProvider), isNot(isA<VaultUnlocked>()));
    await tester.tap(find.text('Confirmer'));
    await settle(tester);
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    await teardownApp(tester);
  });

  testWidgets('Autorisations (Android) : numérisation sans autorisation, notifications', (
    tester,
  ) async {
    usePhoneSize(tester);
    final container = await startUnlocked(tester);
    container.read(routerProvider).go(Routes.settings);
    await settle(tester, rounds: 8);
    await tester.tap(find.text('Autorisations'));
    await settle(tester, rounds: 8);

    expect(
      find.text("Aucune autorisation nécessaire : l'outil de numérisation du téléphone prend la photo."),
      findsOneWidget,
    );
    // Notifications désactivées : la demande du système s'affiche.
    expect(find.textContaining('Désactivées'), findsOneWidget);
    await tester.tap(find.text('Notifications'));
    await settle(tester, rounds: 8);
    expect(env.notifications.permissionRequests, 1);
    expect(find.text("Autorisées, pour les rappels d'échéance."), findsOneWidget);

    // Autorisées : le toucher ouvre les réglages du téléphone.
    await tester.tap(find.text('Notifications'));
    await settle(tester, rounds: 4);
    expect(env.systemSettings.openCalls, 1);
    expect(env.systemSettings.lastOpenedNotifications, isTrue);

    await tester.tap(find.text('Ouvrir les réglages du téléphone'));
    await settle(tester, rounds: 4);
    expect(env.systemSettings.openCalls, 2);
    expect(env.systemSettings.lastOpenedNotifications, isFalse);
    await teardownApp(tester);
  });

  testWidgets('Autorisations (iPhone) : demander puis ouvrir les réglages', (tester) async {
    usePhoneSize(tester);
    env.systemSettings.camera = CameraAccess.notDetermined;
    final container = await startUnlocked(tester);
    container.read(routerProvider).go(Routes.settingsPermissions);
    await settle(tester, rounds: 8);

    await tester.tap(find.text("Touchez pour autoriser l'appareil photo."));
    await settle(tester, rounds: 4);
    expect(env.systemSettings.cameraRequests, 1);
    expect(find.text('Appareil photo autorisé.'), findsOneWidget);

    env.systemSettings.camera = CameraAccess.denied;
    container.read(routerProvider).go(Routes.settings);
    await settle(tester, rounds: 4);
    container.read(routerProvider).go(Routes.settingsPermissions);
    await settle(tester, rounds: 8);
    await tester.tap(find.textContaining('Appareil photo refusé'));
    await settle(tester, rounds: 4);
    expect(env.systemSettings.openCalls, 1);
    await teardownApp(tester);
  });

  testWidgets('scanner : appareil photo refusé, accès direct aux réglages', (tester) async {
    usePhoneSize(tester);
    final scanner = FakeScannerService(error: const ScannerException(cameraDenied: true));
    final container = await startUnlocked(tester, scanner: scanner);
    container.read(routerProvider).go(Routes.scan);
    await settle(tester, rounds: 8);
    await tester.tap(find.text('Numériser'));
    await settle(tester, rounds: 8);

    expect(
      find.text("DocSafe n'a pas accès à l'appareil photo. Autorisez-le dans les réglages du téléphone."),
      findsOneWidget,
    );
    await tester.tap(find.text('Ouvrir les réglages du téléphone'));
    await settle(tester, rounds: 4);
    expect(env.systemSettings.openCalls, 1);

    // Autre échec : message sans bouton vers les réglages.
    scanner.error = const ScannerException();
    await tester.tap(find.text('Numériser'));
    await settle(tester, rounds: 8);
    expect(find.textContaining('Réessayez dans une minute'), findsOneWidget);
    expect(find.text('Ouvrir les réglages du téléphone'), findsNothing);
    await teardownApp(tester);
  });
}
