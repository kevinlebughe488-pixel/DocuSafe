import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:docusafe/app/router/app_router.dart';
import 'package:docusafe/app/router/routes.dart';
import 'package:docusafe/core/database/daos/settings_dao.dart';
import 'package:docusafe/core/documents/ingest_document.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/utils/date_only.dart';
import 'package:docusafe/main.dart' as app;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

/// Visite en captures de la vraie application (aperçu iOS, recette
/// « Aperçu iOS ») : sur un iPhone simulé, elle crée le coffre, ajoute trois
/// documents d'exemple, verrouille, rouvre et parcourt les écrans principaux.
/// Chaque capture est écrite dans le dossier `CAPTURES_DIR` (sur un iPhone
/// simulé, l'application peut écrire dans un dossier du Mac), sinon dans le
/// dossier temporaire de l'application.
///
/// Lancement (simulateur, installation neuve) :
/// `flutter test integration_test/visite_test.dart -d <appareil> --dart-define=CAPTURES_DIR=<dossier>`
///
/// Les documents d'exemple sont des images dessinées ici, pour les captures
/// seulement : ils n'existent que dans ce coffre de test.
const String _capturesDir = String.fromEnvironment('CAPTURES_DIR');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Étapes affichées dans le journal de la recette (aucune donnée).
  void step(String message) => debugPrint('VISITE : $message');

  /// Attend qu'un élément apparaisse (temps réel, au plus [seconds]).
  Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 60}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    fail('Introuvable après $seconds s : $finder');
  }

  /// Laisse finir les animations, puis prend la capture et l'écrit.
  Future<void> capture(WidgetTester tester, String name) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    final List<int> bytes;
    try {
      bytes = await binding.takeScreenshot(name).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      step('capture $name ignorée (délai dépassé)');
      return;
    }
    var dir = Directory(_capturesDir.isNotEmpty ? _capturesDir : '${Directory.systemTemp.path}/captures');
    try {
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
    } on FileSystemException {
      dir = Directory('${Directory.systemTemp.path}/captures');
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
    }
    step('capture $name (${bytes.length} octets) dans ${dir.path}');
  }

  Future<void> typePin(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tester.tap(find.widgetWithText(InkWell, digit).last);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  /// Image d'exemple : une page claire avec un bandeau de couleur et des
  /// lignes grises, comme un document numérisé.
  Future<File> sampleImage(Directory dir, String name, Color color) async {
    const width = 600.0;
    const height = 800.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(const Rect.fromLTWH(0, 0, width, height), Paint()..color = const Color(0xFFF8F8F4))
      ..drawRect(const Rect.fromLTWH(40, 40, 520, 110), Paint()..color = color);
    final line = Paint()..color = const Color(0xFFC9CCD1);
    for (var i = 0; i < 14; i++) {
      canvas.drawRect(Rect.fromLTWH(40, 200 + i * 38.0, 520 - (i % 3) * 90.0, 14), line);
    }
    final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file;
  }

  testWidgets('visite en captures', (tester) async {
    // L'application installe son propre gestionnaire d'erreurs : le test
    // remet celui de flutter_test (une erreur arrête la visite).
    final testErrorHandler = FlutterError.onError;
    await app.main();
    FlutterError.onError = testErrorHandler;
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    step('application lancée');
    await waitFor(tester, find.text('Bienvenue dans DocSafe'));
    await capture(tester, '01-bienvenue');

    // Création du coffre : code de six chiffres, validé tout seul.
    await tester.tap(find.text('Passer'));
    await waitFor(tester, find.text('Choisissez votre code'));
    await typePin(tester, '204');
    await capture(tester, '02-choix-du-code');
    await typePin(tester, '915');
    await waitFor(tester, find.text('Confirmez votre code'));
    await typePin(tester, '204915');

    // Face ID proposé seulement si le simulateur en a un.
    final ready = find.text('Votre coffre est vide');
    final later = find.text('Plus tard');
    final end = DateTime.now().add(const Duration(seconds: 180));
    var biometricCaptured = false;
    while (ready.evaluate().isEmpty && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (later.evaluate().isNotEmpty) {
        if (!biometricCaptured) {
          biometricCaptured = true;
          await capture(tester, '03-face-id');
        }
        await tester.tap(later);
      }
    }
    expect(ready, findsOneWidget);
    step('coffre créé');
    await capture(tester, '04-accueil-vide');

    // Trois documents d'exemple, par le chemin normal de l'importation.
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final temp = container.read(vaultPathsProvider).secureTempDir;
    await temp.create(recursive: true);
    final ingest = container.read(ingestDocumentProvider);
    final today = DateTime.now();
    final samples = [
      ('Passeport', 'default-identity', const Color(0xFF1F5FAF), today.add(const Duration(days: 21))),
      ('Contrat de bail', 'default-housing', const Color(0xFF2E7D6B), null),
      ('Diplôme de licence', 'default-education', const Color(0xFF8A5A9E), null),
    ];
    String? passportId;
    for (final (title, category, color, expires) in samples) {
      final file = await sampleImage(temp, title.hashCode.toUnsigned(32).toString(), color);
      final check = await ingest.check(file) as FileAccepted;
      final row = await ingest(
        IngestRequest(
          source: file,
          fileName: '$title.png',
          check: check,
          title: title,
          categoryId: category,
          expirationDate: expires == null ? null : DateOnly.fromDateTime(expires),
        ),
      );
      passportId ??= row.id;
    }
    await container
        .read(databaseProvider)
        .settingsDao
        .writeConfig(VaultConfigKeys.profileName, 'Awa');
    // L'accueil montre le nombre de documents et les échéances proches.
    step('documents d\'exemple ajoutés');
    await waitFor(tester, find.text('3 documents'));
    await capture(tester, '05-accueil');

    // Cadenas : le coffre se ferme, puis le code le rouvre.
    await tester.tap(find.byTooltip('Verrouiller'));
    await waitFor(tester, find.text('Coffre verrouillé'));
    await capture(tester, '06-coffre-verrouille');
    await typePin(tester, '204915');
    await waitFor(tester, find.text('3 documents'), seconds: 180);
    step('coffre rouvert');

    final router = container.read(routerProvider);
    Future<void> visit(String route, Finder expected, String name) async {
      router.go(route);
      await waitFor(tester, expected);
      await capture(tester, name);
    }

    await visit(Routes.documents, find.text('Contrat de bail'), '07-documents');
    await visit(Routes.document(passportId!), find.text('Passeport'), '08-fiche');
    await visit(Routes.deadlines, find.text('Passeport'), '09-echeances');
    await visit(Routes.scan, find.text('Numériser'), '10-scanner');
    await visit(Routes.settings, find.text('Autorisations'), '11-parametres');
    await visit(Routes.settingsSecurity, find.text('Changer le code'), '12-securite');
    await visit(Routes.settingsPermissions, find.text('Numérisation'), '13-autorisations');
    await visit(Routes.settingsHelp, find.text("J'ai oublié mon code"), '14-aide');
    step('visite terminée');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
