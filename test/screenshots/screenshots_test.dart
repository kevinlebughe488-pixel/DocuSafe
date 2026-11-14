@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:docusafe/app/app.dart';
import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/platform/file_picker_service.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/auth/biometric_service.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:docusafe/features/auth/presentation/setup/setup_view_model.dart';
import 'package:docusafe/features/auth/presentation/unlock/unlock_view_model.dart';
import 'package:docusafe/features/documents/presentation/import/import_view_model.dart';
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
    // iPhone : Face ID ; Android : empreinte.
    biometrics ??= _FakeBiometrics(
      ios ? BiometricKind.face : BiometricKind.fingerprint,
    );
    if (ios) {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      useIphoneSize(tester);
    } else {
      usePhoneSize(tester);
    }
    // Sur un téléphone, aucun cadre de focus clavier n'est dessiné.
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
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

    await both(tester, '05-biometrie', () async {
      await pumpApp(
        tester,
        extra: [
          setupViewModelProvider.overrideWith(
            () => _FixedSetup(
              SetupState(
                stage: SetupStage.biometric,
                biometricKind: ios
                    ? BiometricKind.face
                    : BiometricKind.fingerprint,
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
    await both(tester, '04-cle-de-recuperation', () async {
      await unlock();
      unawaited(
        containerOf(tester).read(routerProvider).push(Routes.recoveryKeyFirstTime),
      );
    });
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

  testWidgets('05 documents, importation, catégories, paramètres', (tester) async {
    await tester.runAsync(createVault);
    final picker = FakeFilePickerService();
    final extra = [
      filePickerServiceProvider.overrideWithValue(picker),
      thumbnailServiceProvider.overrideWithValue(const ImageOnlyThumbnailService()),
    ];

    /// Déverrouille et importe trois documents de démonstration (fichiers de
    /// test du dépôt, données réelles de la base).
    Future<void> unlockWithDocuments() async {
      await pumpApp(tester, extra: extra);
      await tester.runAsync(() async {
        final container = containerOf(tester);
        await container.read(vaultControllerProvider.notifier).unlockWithPin(pin);
        // Les documents de démonstration ne sont ajoutés qu'une fois.
        if (await container.read(databaseProvider).documentsDao.watchCount().first > 0) {
          return;
        }
        final ingest = container.read(ingestDocumentProvider);
        final temp = env.paths.secureTempDir;
        await temp.create(recursive: true);
        Future<void> add(String fixture, String name, String title, String category,
            {DateOnly? expiration, String? type, List<String> tags = const [], bool favorite = false}) async {
          final f = await File('test/fixtures/$fixture').copy('${temp.path}/$name');
          final check = await ingest.check(f) as FileAccepted;
          final row = await ingest(IngestRequest(
            source: f, fileName: name, check: check, title: title,
            categoryId: category, docType: type, expirationDate: expiration, tags: tags,
          ));
          if (favorite) {
            await container.read(documentRepositoryProvider).setFavorite(row.id, true);
          }
        }
        await add('simple.pdf', 'passeport.pdf', 'Passeport', 'default-identity',
            expiration: DateOnly.today().addDays(90), type: 'Passeport', tags: ['voyage'], favorite: true);
        await add('rouge.png', 'IMG_2041.png', 'Carte Vitale', 'default-health');
        await add('simple.pdf', 'bail.pdf', 'Contrat de bail', 'default-housing',
            expiration: DateOnly.today().addDays(12));
        await container.read(databaseProvider).settingsDao.writeConfig('recovery_key_confirmed', true);
      });
      await settle(tester, rounds: 8);
    }

    await both(tester, '13-accueil-rempli', unlockWithDocuments);
    await both(tester, '14-documents', () async {
      await unlockWithDocuments();
      containerOf(tester).read(routerProvider).go(Routes.documents);
    });
    await both(tester, '15-fiche', () async {
      await unlockWithDocuments();
      final docs = await tester.runAsync(
        () => containerOf(tester).read(documentRepositoryProvider).watchFavorites().first,
      );
      unawaited(containerOf(tester).read(routerProvider).push(Routes.document(docs!.first.id)));
    });
    await both(tester, '16-importation', () async {
      await unlockWithDocuments();
      await tester.runAsync(() async {
        final dir = await Directory('${env.root.path}/picked').create();
        picker.documents = [
          PickedFile(file: await File('test/fixtures/simple.pdf').copy('${dir.path}/Facture octobre.pdf'), displayName: 'Facture octobre.pdf'),
          PickedFile(file: await File('test/fixtures/rouge.png').copy('${dir.path}/IMG_2042.png'), displayName: 'IMG_2042.png'),
          PickedFile(file: await File('test/fixtures/notes.txt').copy('${dir.path}/notes.docx'), displayName: 'notes.docx'),
        ];
      });
      containerOf(tester).read(importViewModelProvider.notifier).reset();
      unawaited(containerOf(tester).read(routerProvider).push(Routes.documentsImport, extra: ImportSource.files));
      await settle(tester, rounds: 30);
    });
    await both(tester, '17-categories', () async {
      await unlockWithDocuments();
      unawaited(containerOf(tester).read(routerProvider).push(Routes.categories));
    });
    await both(tester, '18-categorie-modifier', () async {
      await unlockWithDocuments();
      unawaited(containerOf(tester).read(routerProvider).push(Routes.category('default-health')));
    });
    await both(tester, '19-parametres', () async {
      await unlockWithDocuments();
      containerOf(tester).read(routerProvider).go(Routes.settings);
    });
  }, skip: !enabled, timeout: const Timeout(Duration(minutes: 5)));
}

/// Biométrie simulée : disponible, jamais reconnue.
final class _FakeBiometrics implements BiometricService {
  const _FakeBiometrics(this.kind);

  final BiometricKind kind;

  @override
  Future<BiometricKind> availableKind() async => kind;

  @override
  Future<bool> authenticate({required String reason}) async => false;
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
