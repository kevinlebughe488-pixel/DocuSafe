import 'package:docusafe/core/errors/app_exception.dart';
import 'package:docusafe/core/security/auth/pin_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format : 6 chiffres exactement', () {
    for (final pin in ['12345', '1234567', '20491573', '12a456', '']) {
      expect(
        () => PinPolicy.validate(pin),
        throwsA(same(ValidationException.pinFormat)),
        reason: pin,
      );
    }
  });

  test('refusés : six chiffres identiques et suites', () {
    for (final pin in ['000000', '111111', '999999', '123456', '012345', '456789', '654321', '987654']) {
      expect(
        () => PinPolicy.validate(pin),
        throwsA(same(ValidationException.pinTooSimple)),
        reason: pin,
      );
    }
  });

  test('acceptés : les autres codes, même faciles à retenir (D5 révisée)', () {
    for (final pin in ['112233', '121212', '123123', '998877', '204915', '731906', '102030', '113355']) {
      expect(() => PinPolicy.validate(pin), returnsNormally, reason: pin);
    }
  });
}
