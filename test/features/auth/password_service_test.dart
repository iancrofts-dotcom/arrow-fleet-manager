import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A lower work factor keeps these unit tests fast. Production uses the
  // PasswordService default of 12 rounds.
  const passwords = PasswordService(workFactor: 4);

  group('PasswordService', () {
    test('verifies a correct bcrypt password', () {
      final hash = passwords.hash('correct horse battery staple');

      expect(passwords.isSecureHash(hash), isTrue);
      expect(
        passwords.verify(
          plainTextPassword: 'correct horse battery staple',
          storedValue: hash,
        ),
        isTrue,
      );
    });

    test('rejects an incorrect bcrypt password', () {
      final hash = passwords.hash('correct-password');

      expect(
        passwords.verify(
          plainTextPassword: 'incorrect-password',
          storedValue: hash,
        ),
        isFalse,
      );
    });

    test('valid legacy plaintext credentials can be upgraded to bcrypt', () {
      const legacyPassword = 'legacy-password';

      expect(passwords.needsMigration(legacyPassword), isTrue);
      expect(
        passwords.verify(
          plainTextPassword: legacyPassword,
          storedValue: legacyPassword,
        ),
        isTrue,
      );

      final migratedHash = passwords.hash(legacyPassword);
      expect(passwords.isSecureHash(migratedHash), isTrue);
      expect(
        passwords.verify(
          plainTextPassword: legacyPassword,
          storedValue: migratedHash,
        ),
        isTrue,
      );
    });

    test('invalid legacy credentials do not verify', () {
      expect(
        passwords.verify(
          plainTextPassword: 'incorrect-password',
          storedValue: 'legacy-password',
        ),
        isFalse,
      );
    });

    test('new and changed passwords are stored as distinct bcrypt hashes', () {
      final newUserHash = passwords.hash('initial-password');
      final changedPasswordHash = passwords.hash('changed-password');

      expect(newUserHash, isNot('initial-password'));
      expect(changedPasswordHash, isNot('changed-password'));
      expect(changedPasswordHash, isNot(newUserHash));
      expect(
        passwords.verify(
          plainTextPassword: 'changed-password',
          storedValue: changedPasswordHash,
        ),
        isTrue,
      );
      expect(
        passwords.verify(
          plainTextPassword: 'initial-password',
          storedValue: changedPasswordHash,
        ),
        isFalse,
      );
    });
  });
}
