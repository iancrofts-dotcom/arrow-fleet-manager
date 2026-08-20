import '../../drivers/models/driver.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'user_service.dart';

class UserSyncService {
  UserSyncService({UserService? userService})
    : _userService = userService ?? UserService.instance;

  static final UserSyncService instance = UserSyncService();

  final UserService _userService;

  Future<bool> isUsernameInUse(String username) async {
    return await _userService.getUserByUsername(username) != null;
  }

  /// Creates the first linked account for a newly persisted Driver.
  ///
  /// The plaintext password is passed straight to [UserService.addUser], which
  /// is responsible for bcrypt hashing it before persistence.
  Future<void> createDriverUser(
    Driver driver, {
    required String password,
  }) async {
    final driverId = driver.id;
    final username = driver.username;
    if (driverId == null || username == null || username.isEmpty) {
      throw ArgumentError(
        'A saved driver with a username is required to create an account.',
      );
    }

    final existingUser = await _userService.findUser(driverId: driverId);
    if (existingUser != null) {
      throw StateError('A user account already exists for this driver.');
    }

    final user = User(
      id: _generateUserId(),
      username: username,
      passwordHash: '',
      role: UserRole.driver,
      driverId: driverId,
      isActive: driver.isActive,
    );

    await _userService.addUser(user, password: password);
  }

  /// Updates an existing login account associated with a Driver.
  ///
  /// Initial account creation must use [createDriverUser] so a plaintext
  /// password is hashed by [UserService] before it is persisted.
  Future<void> syncDriver(Driver driver) async {
    if (driver.id == null) {
      throw ArgumentError(
        'Driver must have an ID before a user account can be synchronised.',
      );
    }

    final existingUser = await _userService.findUser(driverId: driver.id);

    if (existingUser == null) {
      throw StateError('No linked user account exists for this driver.');
    }

    final user = _buildUser(driver, existing: existingUser);

    await _userService.saveUser(user);
  }

  /// Converts a Driver into a User.
  User _buildUser(Driver driver, {required User existing}) {
    return User(
      id: existing.id,
      username: driver.username ?? '',
      passwordHash: existing.passwordHash,
      role: existing.role,
      driverId: driver.id,
      isActive: driver.isActive,
    );
  }

  /// Removes the user account associated with a driver.
  Future<void> deleteDriverUser(int driverId) async {
    final existingUser = await _userService.findUser(driverId: driverId);

    if (existingUser != null) {
      await _userService.deleteUser(existingUser.id);
    }
  }

  /// Temporary ID generator.
  ///
  /// TODO: Replace with UUID or a database-generated ID.
  String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
