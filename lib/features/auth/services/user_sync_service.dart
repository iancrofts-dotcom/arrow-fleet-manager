import '../../drivers/models/driver.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'user_service.dart';

class UserSyncService {
  UserSyncService._();

  static final UserSyncService instance = UserSyncService._();

  final UserService _userService = UserService.instance;

  /// Creates or updates the login account associated with a driver.
  Future<void> syncDriver(Driver driver) async {
    if (driver.id == null) {
      throw ArgumentError(
        'Driver must have an ID before a user account can be synchronised.',
      );
    }

    final existingUser = await _userService.findUser(
      driverId: driver.id,
    );

    final user = _buildUser(
      driver,
      existing: existingUser,
    );

    await _userService.saveUser(user);
  }

  /// Converts a Driver into a User.
  User _buildUser(
    Driver driver, {
    User? existing,
  }) {
    return User(
      id: existing?.id ?? _generateUserId(),
      username: driver.username ?? '',
      passwordHash: existing?.passwordHash ?? '',
      role: existing?.role ?? UserRole.driver,
      driverId: driver.id,
      isActive: driver.isActive,
    );
  }
    /// Removes the user account associated with a driver.
  Future<void> deleteDriverUser(
    int driverId,
  ) async {
    final existingUser = await _userService.findUser(
      driverId: driverId,
    );

    if (existingUser != null) {
      await _userService.deleteUser(
        existingUser.id,
      );
    }
  }

  /// Temporary ID generator.
  ///
  /// TODO: Replace with UUID or a database-generated ID.
  String _generateUserId() {
    return DateTime.now()
        .millisecondsSinceEpoch
        .toString();
  }
}