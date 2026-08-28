/// Shared policy for newly created or replacement passwords.
class PasswordPolicy {
  const PasswordPolicy._();

  static const int minimumPasswordLength = 8;
  static const String minimumLengthMessage =
      'Password must be at least 8 characters.';

  static bool isValid(String password) =>
      password.length >= minimumPasswordLength;

  static String? validate(String password) =>
      isValid(password) ? null : minimumLengthMessage;
}
