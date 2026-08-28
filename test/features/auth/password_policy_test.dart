import 'package:arrow_fleet_manager/features/auth/services/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordPolicy', () {
    test('rejects passwords shorter than eight characters', () {
      for (final password in ['', 'a', '1234567']) {
        expect(PasswordPolicy.isValid(password), isFalse);
        expect(
          PasswordPolicy.validate(password),
          PasswordPolicy.minimumLengthMessage,
        );
      }
    });

    test('accepts passwords with at least eight characters', () {
      expect(PasswordPolicy.isValid('12345678'), isTrue);
      expect(PasswordPolicy.validate('12345678'), isNull);
      expect(PasswordPolicy.isValid('longer-password'), isTrue);
    });
  });
}
