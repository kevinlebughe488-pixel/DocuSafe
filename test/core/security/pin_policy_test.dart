import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/security/auth/pin_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format : 6 à 12 chiffres', () {
    expect(() => PinPolicy.validate('12345'), throwsA(same(ValidationException.pinFormat)));
    expect(() => PinPolicy.validate('1234567890123'), throwsA(same(ValidationException.pinFormat)));
    expect(() => PinPolicy.validate('12a456'), throwsA(same(ValidationException.pinFormat)));
    expect(() => PinPolicy.validate(''), throwsA(same(ValidationException.pinFormat)));
  });

  test('codes trop simples refusés', () {
    for (final pin in [
      '000000',
      '111111',
      '123456',
      '654321',
      '345678',
      '121212',
      '123123',
      '112233',
      '998877',
      '12345678',
      '00000000',
    ]) {
      expect(
        () => PinPolicy.validate(pin),
        throwsA(same(ValidationException.pinTooSimple)),
        reason: pin,
      );
    }
  });

  test('codes acceptables', () {
    for (final pin in ['204915', '731906', '102030', '135790', '2468013579', '113355']) {
      expect(() => PinPolicy.validate(pin), returnsNormally, reason: pin);
    }
  });
}
