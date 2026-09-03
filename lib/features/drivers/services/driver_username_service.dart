import '../../auth/services/user_service.dart';

/// Generates unique login identities for newly created Driver accounts.
class DriverUsernameService {
  DriverUsernameService({UserService? userService})
    : _userService = userService ?? UserService.instance;

  final UserService _userService;

  /// Produces the predictable, read-only Add Driver preview.
  static String baseUsername(String firstName, String lastName) {
    final normalizedFirstName = _normalizeNamePart(firstName);
    final normalizedLastName = _normalizeNamePart(lastName);

    if (normalizedFirstName.isEmpty || normalizedLastName.isEmpty) {
      return '';
    }

    return '$normalizedFirstName.$normalizedLastName';
  }

  /// Resolves the final available username immediately before Driver creation.
  Future<String> generateUsername({
    required String firstName,
    required String lastName,
  }) async {
    final base = baseUsername(firstName, lastName);
    if (base.isEmpty) {
      throw ArgumentError(
        'A first name and last name are required to generate a username.',
      );
    }

    var candidate = base;
    var suffix = 2;
    while (!await _userService.isUsernameAvailable(candidate)) {
      candidate = '$base$suffix';
      suffix++;
    }

    return candidate;
  }

  static String _normalizeNamePart(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}
