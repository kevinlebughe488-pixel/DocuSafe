import 'package:docusafe/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';

/// Régression : les fournisseurs gardaient la base fermée de la première
/// session après un verrouillage (signalé le 14/11/2026).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('après verrouillage puis déverrouillage, la base est celle de la nouvelle session', () async {
    final env = await TestEnvironment.create();
    final c = ProviderContainer(overrides: env.overrides());
    final ctrl = c.read(vaultControllerProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await ctrl.commitSetup(await ctrl.prepareSetup('204915'));
    final db1 = c.read(databaseProvider);
    await ctrl.lock();
    await ctrl.unlockWithPin('204915');
    final db2 = c.read(databaseProvider);
    expect(identical(db1, db2), isFalse);
    expect(identical(c.read(sessionProvider).database, db2), isTrue);
    await db2.documentsDao.getAll();
    c.dispose();
    await env.dispose();
  });
}
