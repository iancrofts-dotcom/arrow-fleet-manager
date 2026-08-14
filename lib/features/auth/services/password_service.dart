import 'package:bcrypt/bcrypt.dart';

/// Creates and verifies the credentials stored in the users table.
///
/// The application previously stored legacy passwords as plain text.  A valid
/// legacy password is accepted only by [verify] so that [UserService] can
/// replace it with a bcrypt hash during login.
class PasswordService {
  const PasswordService({this.workFactor = 12});

  final int workFactor;

  static final RegExp _bcryptHash = RegExp(
    r'^\$2[aby]\$\d\d\$[./A-Za-z0-9]{53}$',
  );

  bool isSecureHash(String value) => _bcryptHash.hasMatch(value);

  bool needsMigration(String storedValue) => !isSecureHash(storedValue);

  String hash(String plainTextPassword) {
    return BCrypt.hashpw(
      plainTextPassword,
      BCrypt.gensalt(logRounds: workFactor),
    );
  }

  bool verify({
    required String plainTextPassword,
    required String storedValue,
  }) {
    if (isSecureHash(storedValue)) {
      return BCrypt.checkpw(plainTextPassword, storedValue);
    }

    // Legacy migration only. New credentials are always bcrypt hashes.
    return plainTextPassword == storedValue;
  }
}
