import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:docusafe/app/app.dart';
import 'package:docusafe/app/l10n/generated/app_localizations.dart';
import 'package:docusafe/app/theme/app_theme.dart';
import 'package:docusafe/core/database/app_database.dart';
import 'package:docusafe/core/platform/notification_service.dart';
import 'package:docusafe/core/platform/share_intake_service.dart';
import 'package:docusafe/core/platform/share_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/auth/biometric_service.dart';
import 'package:docusafe/core/security/auth/pin_attempts.dart';
import 'package:docusafe/core/security/crypto/argon2_params.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/screen/screen_security.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/core/storage/vault_paths.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Environnement de test : stockage sécurisé en mémoire, dossiers temporaires,
/// pas de biométrie, Argon2id léger.
final class TestEnvironment {
  TestEnvironment._(this.root, this.store, this.biometricStore);

  static Future<TestEnvironment> create() async {
    final root = await Directory.systemTemp.createTemp('docusafe_widget');
    return TestEnvironment._(
      root,
      InMemorySecureStore(),
      InMemorySecureStore(),
    );
  }

  final Directory root;
  final InMemorySecureStore store;
  final InMemorySecureStore biometricStore;

  /// Notifications simulées : ce qui serait programmé.
  final FakeNotificationService notifications = FakeNotificationService();

  /// Partage et « Enregistrer sous » simulés : ce qui serait sorti.
  final FakeShareService shares = FakeShareService();

  /// « Partager vers DocSafe » simulé : fichiers reçus d'une autre application.
  final FakeShareIntakeService shareIntake = FakeShareIntakeService();

  VaultPaths get paths => VaultPaths.under(root);

  List<Override> overrides({BiometricService? biometrics}) => [
    vaultPathsProvider.overrideWithValue(paths),
    secureStoreProvider.overrideWithValue(store),
    biometricStoreProvider.overrideWithValue(biometricStore),
    biometricServiceProvider.overrideWithValue(
      biometrics ?? const NoBiometricService(),
    ),
    screenSecurityProvider.overrideWithValue(const NoopScreenSecurity()),
    notificationServiceProvider.overrideWithValue(notifications),
    shareServiceProvider.overrideWithValue(shares),
    shareIntakeServiceProvider.overrideWithValue(shareIntake),
    vaultServiceProvider.overrideWith(
      (ref) => VaultService(
        crypto: ref.watch(cryptoEngineProvider),
        store: store,
        biometricStore: biometricStore,
        paths: paths,
        attempts: PinAttempts(store),
        argon2Params: Argon2Params.testOnly,
        openDatabase: AppDatabase.openEncryptedInline,
      ),
    ),
  ];

  Future<void> dispose() => root.delete(recursive: true);
}

/// L'application complète, avec les services de test.
Widget testApp(TestEnvironment env, {BiometricService? biometrics}) =>
    ProviderScope(
      overrides: env.overrides(biometrics: biometrics),
      child: testAppChild(),
    );

/// L'application seule, à placer dans un `ProviderScope` personnalisé.
Widget testAppChild() => const DocSafeApp();

/// Un widget seul, dans une MaterialApp avec les textes français.
Widget wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        // Thème de l'application (couleurs DocSafe, extension DsColors).
        theme: AppTheme.light(),
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );

/// Tape un code sur le clavier dessiné par l'application.
Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.widgetWithText(InkWell, d).last);
    await tester.pump();
  }
}

/// Laisse le temps aux opérations réelles (isolates, fichiers) de finir et
/// fait avancer les animations de changement d'écran.
Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Démonte l'application et laisse drift et le contrôleur fermer la base :
/// évite les minuteurs encore actifs à la fin d'un test.
Future<void> teardownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(Duration.zero);
  }
}

/// Taille d'un iPhone 15 (393 × 852 points, densité 3).
void useIphoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Taille d'un téléphone courant (360 × 800 points).
/// Petit téléphone d'entrée de gamme : 320 × 640 points, barre d'état et
/// barre de navigation à trois boutons (celui de l'émulateur de GitHub).
void useSmallPhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
  addTearDown(tester.view.reset);
}

void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
