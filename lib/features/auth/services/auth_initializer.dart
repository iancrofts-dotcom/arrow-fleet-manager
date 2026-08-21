import 'user_service.dart';

class AuthInitializer {
  AuthInitializer({UserService? userService})
    : _userService = userService ?? UserService.instance;

  static final AuthInitializer instance = AuthInitializer();

  final UserService _userService;

  /// Whether the application must provision its first active Administrator.
  Future<bool> requiresFirstAdministratorSetup() {
    return _userService.requiresFirstAdministratorSetup();
  }
}
