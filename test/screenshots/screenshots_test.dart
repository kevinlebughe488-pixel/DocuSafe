@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:docusafe/app/app.dart';
import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/auth/biometric_service.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/features/auth/presentation/setup/setup_view_model.dart';
import 'package:docusafe/features/auth/presentation/unlock/unlock_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Captures d'écran des interfaces, en clair et en sombre, écrites dans
/// `docs/captures/`. Elles ne sont produites que sur demande :
///
/// ```bash
/// DOCUSAFE_SCREENSHOTS=1 flutter test test/screenshots --update-goldens
/// ```
///
/// Les polices Roboto et Material Icons sont chargées depuis le SDK Flutter,
/// pour un rendu fidèle à Android.
///
/// Avec `DOCUSAFE_PLATFORM=ios`, les écrans sont rendus comme sur un iPhone 15
/// (composants adaptatifs, transitions et flèche de retour iOS) dans
/// `docs/captures/ios/`. La police San Francisco d'Apple n'étant pas
/// disponible hors d'un Mac, le texte y est rendu en Roboto : sur un vrai
/// iPhone, la police sera San Francisco. À vérifier sur iOS.
void main() {
  final enabled = Platform.environment['DOCUSAFE_SCREENSHOTS'] == '1';
  final ios = Platform.environment['DOCUSAFE_PLATFORM'] == 'ios';
  final outputDir = ios ? '../../docs/captures/ios' : '../../docs/captures';
  const pin = '204915';

  setUpAll(() async {
    if (!enabled) {
      return;
    }
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/home/user/sdk/flutter';
    final fontsDir = Directory('$sdk/bin/cache/artifacts/material_fonts');
    if (!fontsDir.existsSync()) {
      fail('Polices introuvables : ${fontsDir.path}');
    }
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        final bytes = await File('${fontsDir.path}/$f').readAsBytes();
        loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      }
      await loader.load();
    }
    const roboto = ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'];
    await load('Roboto', roboto);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
    await load('monospace', ['RobotoCondensed-Regular.ttf']);
    if (ios) {
      // Noms de famille utilisés par la typographie iOS de Flutter.
      await load('CupertinoSystemText', roboto);
      await load('CupertinoSystemDisplay', roboto);
    }
  });

  late TestEnvironment env;

  setUp(() async {
    env = await TestEnvironment.create();
  });

  tearDown(() => env.dispose());

  Future<void> shoot(WidgetTester tester, String name) async {
    await settle(tester, rounds: 8);
    await expectLater(
      find.byType(DocuSafeApp),
      matchesGoldenFile('$outputDir/$name.png'),
    );
  }

  /// Rend la même scène en clair puis en sombre.
  Future<void> both(
    WidgetTester tester,
    String name,
    Future<void> Function() prepare,
  ) async {
    for (final dark in [false, true]) {
      tester.platformDispatcher.platformBrightnessTestValue =
          dark ? Brightness.dark : Brightness.light;
      await prepare();
      await shoot(tester, dark ? '$name-sombre' : name);
      await teardownApp(tester);
      // Le cadre de test exige que ce réglage soit remis avant la fin du test.
      debugDefaultTargetPlatformOverride = null;
    }
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(DocuSafeApp)));

  Future<void> createVault() async {
    final service = env.overrides().isEmpty
        ? throw StateError('env')
        : ProviderContainer(overrides: env.overrides()).read(vaultServiceProvider);
    final pending = await service.prepareSetup(pin);
    final session = await service.commitSetup(pending);
    await session.close();
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    List<Override> extra = const [],
    BiometricService? biometrics,
  }) async {
    if (ios) {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      useIphoneSize(tester);
    } else {
      usePhoneSize(tester);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...env.overrides(biometrics: biometrics), ...extra],
        child: const DocuSafeApp(),
      ),
    );
    await settle(tester, rounds: 8);
  }

  testWidgets('01 démarrage et onboarding', (tester) async {
    await both(tester, '01-onboarding-1', () => pumpApp(tester));
    await both(tester, '02-onboarding-4', () async {
      await pumpApp(tester);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Suivant'));
        await settle(tester, rounds: 5);
      }
    });
  }, skip: !enabled);

  testWidgets('02 création du coffre', (tester) async {
    await both(tester, '03-creation-code', () async {
      await pumpApp(tester);
      containerOf(tester).read(routerProvider).go(Routes.setup);
      await settle(tester, rounds: 5);
      await typePin(tester, '204');
    });

    // Clé de récupération : coffre préparé mais pas enregistré.
    PendingVaultSetup? pending;
    await tester.runAsync(() async {
      final service = ProviderContainer(
        overrides: env.overrides(),
      ).read(vaultServiceProvider);
      pending = await service.prepareSetup(pin);
    });
    await both(tester, '04-cle-de-recuperation', () async {
      await pumpApp(
        tester,
        extra: [
          setupViewModelProvider.overrideWith(
            () => _FixedSetup(
              SetupState(stage: SetupStage.recoveryKey, pending: pending),
            ),
          ),
        ],
      );
      containerOf(tester).read(routerProvider).go(Routes.setup);
    });
    await both(tester, '05-biometrie', () async {
      await pumpApp(
        tester,
        extra: [
          setupViewModelProvider.overrideWith(
            () => _FixedSetup(
              const SetupState(
                stage: SetupStage.biometric,
                biometricKind: BiometricKind.fingerprint,
              ),
            ),
          ),
        ],
      );
      containerOf(tester).read(routerProvider).go(Routes.setup);
    });
  }, skip: !enabled);

  testWidgets('03 déverrouillage', (tester) async {
    await tester.runAsync(createVault);
    await both(tester, '06-deverrouillage', () async {
      await env.store.write('vault.flag.biometric', '1');
      await pumpApp(
        tester,
        extra: [
          unlockViewModelProvider.overrideWith(
            () => _FixedUnlock(const UnlockState()),
          ),
        ],
      );
      await typePin(tester, '20');
    });
    await both(tester, '07-trop-d-essais', () async {
      await env.store.write('vault.flag.biometric', '0');
      final now = DateTime.now();
      await pumpApp(
        tester,
        extra: [
          unlockViewModelProvider.overrideWith(
            () => _FixedUnlock(
              UnlockState(
                lockedUntil: now.add(const Duration(seconds: 28)),
                now: now,
              ),
            ),
          ),
        ],
      );
    });
    await both(tester, '08-code-oublie', () async {
      await pumpApp(tester);
      unawaited(containerOf(tester).read(routerProvider).push(Routes.lockRecovery));
      await settle(tester, rounds: 5);
      await tester.enterText(
        find.byType(TextField),
        '7K3M-Q9XD-2HFP-W8TN-4R',
      );
    });
  }, skip: !enabled);

  testWidgets('04 coffre ouvert', (tester) async {
    await tester.runAsync(createVault);
    Future<void> unlock() async {
      await pumpApp(tester);
      await tester.runAsync(
        () => containerOf(tester)
            .read(vaultControllerProvider.notifier)
            .unlockWithPin(pin),
      );
      await settle(tester, rounds: 8);
    }

    await both(tester, '09-accueil', unlock);
    await both(tester, '10-securite', () async {
      await unlock();
      containerOf(tester).read(routerProvider).go(Routes.settingsSecurity);
    });
    await both(tester, '11-changer-le-code', () async {
      await unlock();
      containerOf(tester).read(routerProvider).go(Routes.settingsChangePin);
    });
    await both(tester, '12-confidentialite', () async {
      await unlock();
      unawaited(containerOf(tester).read(routerProvider).push(Routes.legalPrivacy));
    });
  }, skip: !enabled);
}

final class _FixedSetup extends SetupViewModel {
  _FixedSetup(this.fixed);

  final SetupState fixed;

  @override
  SetupState build() => fixed;
}

final class _FixedUnlock extends UnlockViewModel {
  _FixedUnlock(this.fixed);

  final UnlockState fixed;

  @override
  UnlockState build() => fixed;

  @override
  Future<void> tryBiometrics() async {}
}
