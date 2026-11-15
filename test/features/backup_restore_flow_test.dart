import 'dart:io';

import 'package:docusafe/core/backup/backup_service.dart';
import 'package:docusafe/core/platform/file_picker_service.dart';
import 'package:docusafe/core/providers.dart';
import 'package:docusafe/core/security/auth/pin_attempts.dart';
import 'package:docusafe/core/security/crypto/argon2_params.dart';
import 'package:docusafe/core/security/crypto/dart_crypto_engine.dart';
import 'package:docusafe/core/security/keys/secure_store.dart';
import 'package:docusafe/core/security/lock/vault_state.dart';
import 'package:docusafe/core/security/vault_service.dart';
import 'package:docusafe/core/storage/vault_paths.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/test_app.dart';

/// Restaurer une sauvegarde sur un téléphone neuf, depuis l'accueil (D13).
void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  testWidgets('accueil → « J\'ai une sauvegarde » → clé → code → coffre restauré', (
    tester,
  ) async {
    usePhoneSize(tester);
    // Un autre téléphone crée la sauvegarde.
    late File backup;
    late String recoveryKey;
    await tester.runAsync(() async {
      final other = VaultPaths.under(Directory('${env.root.path}/autre'));
      final store = InMemorySecureStore();
      final service = VaultService(
        crypto: const DartCryptoEngine(),
        store: store,
        biometricStore: null,
        paths: other,
        attempts: PinAttempts(store),
        argon2Params: Argon2Params.testOnly,
      );
      final pending = await service.prepareSetup('204915');
      recoveryKey = pending.recoveryKey.display;
      final session = await service.commitSetup(pending);
      final file = await BackupService(paths: other)
          .create(session, now: DateTime(2026, 11, 2, 9));
      backup = await file.copy('${env.root.path}/recue.docsafe');
      await session.close();
    });

    final picker = FakeFilePickerService(
      backup: PickedFile(file: backup, displayName: 'recue.docsafe'),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides(),
          filePickerServiceProvider.overrideWithValue(picker),
        ],
        child: testAppChild(),
      ),
    );
    await settle(tester, rounds: 8);
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

    await tester.tap(find.text("J'ai une sauvegarde"));
    await settle(tester, rounds: 8);
    expect(find.text('Restaurer une sauvegarde'), findsOneWidget);
    await tester.tap(find.text('Choisir le fichier'));
    await settle(tester, rounds: 30);
    expect(find.textContaining('Sauvegarde du'), findsOneWidget);
    expect(find.textContaining('Aucun document'), findsOneWidget);

    // Mauvaise clé : refusée.
    await tester.enterText(find.byType(TextField), 'A' * 32);
    await tester.pump();
    await tester.tap(find.text('Vérifier la clé'));
    await settle(tester, rounds: 10);
    expect(find.text('Choisissez votre code'), findsNothing);

    await tester.enterText(find.byType(TextField), recoveryKey);
    await tester.pump();
    await tester.tap(find.text('Vérifier la clé'));
    await settle(tester, rounds: 10);
    expect(find.text('Choisissez votre code'), findsOneWidget);
    await typePin(tester, '813572');
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await typePin(tester, '813572');
    await tester.tap(find.text('Continuer'));
    await settle(tester, rounds: 40);

    expect(container.read(vaultControllerProvider), isA<VaultUnlocked>());
    expect(find.text('Sauvegarde restaurée.'), findsOneWidget);
    await teardownApp(tester);
  });
}
