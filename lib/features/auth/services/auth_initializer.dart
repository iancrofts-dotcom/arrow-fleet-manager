import '../models/user.dart';
import '../models/user_role.dart';
import 'user_service.dart';

class AuthInitializer {
  AuthInitializer._();

  static final AuthInitializer instance = AuthInitializer._();

  final UserService _userService = UserService.instance;

  Future<void> initialize() async {
    // Create admin if missing
    final adminUser = await _userService.getUserByUsername('admin');
    if (adminUser == null) {
      await _userService.addUser(
        const User(
          id: 'admin',
          username: 'admin',
          passwordHash: '',
          role: UserRole.admin,
        ),
        // Development-only bootstrap credential. It is hashed before storage.
        password: 'admin',
      );
    }

    // Create manager if missing
    final managerUser = await _userService.getUserByUsername('manager');
    if (managerUser == null) {
      await _userService.addUser(
        const User(
          id: 'manager',
          username: 'manager',
          passwordHash: '',
          role: UserRole.manager,
        ),
        // Development-only bootstrap credential. It is hashed before storage.
        password: 'manager',
      );
    }
  }
}
