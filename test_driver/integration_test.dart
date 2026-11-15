import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Pilote de `flutter drive` pour la visite en captures
/// (integration_test/visite_test.dart) : chaque capture est écrite dans le
/// dossier `captures-ios/` (recette « Aperçu iOS »).
Future<void> main() => integrationDriver(
  onScreenshot: (name, image, [args]) async {
    final file = File('captures-ios/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(image);
    return true;
  },
);
