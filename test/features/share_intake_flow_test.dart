import 'dart:io';

import 'package:docusafe/core/platform/file_picker_service.dart';
import 'package:docusafe/core/platform/thumbnail_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/lock/vault_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// « Partager vers DocSafe » (cahier des charges §3.4) : un fichier envoyé
/// par une autre application attend le déverrouillage, puis suit
/// l'importation habituelle.
void main() {
  late TestEnvironment env;
  late Directory sharedDir;

  setUp(() async {
    env = await TestEnvironment.create();
    sharedDir = await Directory('${env.root.path}/shared_in').create();
  });

  tearDown(() => env.dispose());

  testWidgets('fichier partagé coffre verrouillé, puis coffre ouvert', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          thumbnailServiceProvider.overrideWithValue(const ImageOnlyThumbnailService()),
        ],
        child: testAppChild(),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Passer'));
    await settle(tester, rounds: 5);
    await typePin(tester, '204915');
    await tester.pump();
    await typePin(tester, '204915');
    await settle(tester, rounds: 40);
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

    // Coffre verrouillé : le fichier reçu attend.
    await tester.runAsync(() => container.read(vaultControllerProvider.notifier).lock());
    await settle(tester, rounds: 6);
    late File received;
    await tester.runAsync(() async {
      received = await File('test/fixtures/simple.pdf').copy('${sharedDir.path}/Attestation.pdf');
    });
    env.shareIntake.deliver([PickedFile(file: received, displayName: 'Attestation.pdf')]);
    await settle(tester, rounds: 6);
    expect(find.text('Coffre verrouillé'), findsOneWidget);
    expect(container.read(pendingSharesProvider), hasLength(1));

    // Déverrouillage : l'importation s'ouvre avec le fichier reçu.
    await typePin(tester, '204915');
    await settle(tester, rounds: 40);
    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    expect(find.text('1 fichier sélectionné'), findsOneWidget);
    expect(container.read(pendingSharesProvider), isEmpty);
    // La copie reçue est passée dans le dossier temporaire privé.
    expect(received.existsSync(), isFalse);

    await tester.tap(find.text('Continuer avec 1 fichier'));
    await settle(tester, rounds: 10);
    await tester.tap(find.text('Enregistrer dans le coffre'));
    await settle(tester, rounds: 60);
    expect(find.text('Attestation'), findsOneWidget);
    expect(env.paths.secureTempDir.listSync(), isEmpty);
    expect(env.paths.filesDir.listSync(recursive: true).whereType<File>().length, 1);

    // Coffre ouvert : un nouveau partage ouvre l'importation aussitôt.
    late File second;
    await tester.runAsync(() async {
      second = await File('test/fixtures/rouge.png').copy('${sharedDir.path}/Photo.png');
    });
    env.shareIntake.deliver([PickedFile(file: second, displayName: 'Photo.png')]);
    await settle(tester, rounds: 40);
    expect(find.text('1 fichier sélectionné'), findsOneWidget);
    await teardownApp(tester);
  });
}
