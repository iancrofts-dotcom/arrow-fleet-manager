import '../models/user.dart';
import '../models/user_role.dart';
import 'user_service.dart';

class AuthInitializer {
  AuthInitializer._();

  static final AuthInitializer instance = AuthInitializer._();

  final UserService _userService = UserService.instance;

  Future<void> initialize() async {
    // Default Administrator
    const admin = User(
      id: 'admin',
      username: 'admin',
      passwordHash: 'admin',
      role: UserRole.admin,
      driverId: null,
      isActive: true,
    );

    // Default Fleet Manager
    const manager = User(
      id: 'manager',
      username: 'manager',
      passwordHash: 'manager',
      role: UserRole.manager,
      driverId: null,
      isActive: true,
    );

    // Create admin if missing
    final adminUser = await _userService.getUserByUsername('admin');
    if (adminUser == null) {
      await _userService.saveUser(admin);
    }

    // Create manager if missing
    final managerUser = await _userService.getUserByUsername('manager');
    if (managerUser == null) {
      await _userService.saveUser(manager);
    }
  }
}