import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/security/keys/recovery_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('32 caractères en 8 groupes, sans I L O U', () {
    for (var i = 0; i < 50; i++) {
      final key = RecoveryKey.generate();
      final display = key.display;
      expect(display.length, 32 + 7);
      expect(display.split('-').length, 8);
      expect(display.contains(RegExp('[ILOU-]')), display.contains('-'));
      expect(display.replaceAll('-', '').contains(RegExp('[ILOU]')), isFalse);
      expect(RecoveryKey.parse(display).bytes, key.bytes);
    }
  });

  test('saisie tolérante : minuscules, espaces, sans tirets', () {
    final key = RecoveryKey.generate();
    final loose = key.display.toLowerCase().replaceAll('-', ' ');
    expect(RecoveryKey.parse(loose).bytes, key.bytes);
    expect(RecoveryKey.parse(key.display.replaceAll('-', '')).bytes, key.bytes);
  });

  test('clé mal formée refusée', () {
    expect(
      () => RecoveryKey.parse('ABCD'),
      throwsA(isA<AuthException>()),
    );
    final key = RecoveryKey.generate().display;
    // Caractère interdit à la place du premier.
    expect(
      () => RecoveryKey.parse('I${key.substring(1)}'),
      throwsA(isA<AuthException>()),
    );
  });

  test('compteur de caractères saisis', () {
    expect(RecoveryKey.countValidChars('7K3M-Q9XD-2H'), 10);
    expect(RecoveryKey.countValidChars('7k3m q9xd'), 8);
    expect(RecoveryKey.countValidChars(''), 0);
  });
}
