import '../models/user.dart';
import '../models/user_entity.dart';
import '../models/user_role.dart';
import '../repositories/user_repository.dart';
import 'password_service.dart';
import 'password_policy.dart';

class UserService {
  UserService({UserRepository? repository, PasswordService? passwordService})
    : _repository = repository ?? UserRepository(),
      _passwordService = passwordService ?? const PasswordService();

  static final UserService instance = UserService();

  final UserRepository _repository;
  final PasswordService _passwordService;

  static const _legacySeedCredentials = <String, String>{
    'admin': 'admin',
    'manager': 'manager',
  };

  /// Attempts to authenticate a user.
  /// Attempts to authenticate a user.
  Future<User?> login({
    required String username,
    required String password,
  }) async {
    final user = await getUserByUsername(username);

    if (user == null ||
        !user.isActive ||
        !_passwordService.verify(
          plainTextPassword: password,
          storedValue: user.passwordHash,
        )) {
      return null;
    }

    // Detect historical seeded credentials before the legacy plaintext
    // migration can turn them into a normal bcrypt hash.
    if (requiresPasswordChange(user)) {
      return user;
    }

    if (_passwordService.needsMigration(user.passwordHash)) {
      final migratedUser = user.copyWith(
        passwordHash: _passwordService.hash(password),
      );
      await _repository.updateUser(UserEntity.fromUser(migratedUser));
      return migratedUser;
    }

    return user;
  }

  /// True only for the historical fixed bootstrap account/password pairs.
  /// A same-named user who has changed their password is not flagged.
  bool requiresPasswordChange(User user) {
    final historicalPassword = _legacySeedCredentials[user.username];
    return historicalPassword != null &&
        _passwordService.verify(
          plainTextPassword: historicalPassword,
          storedValue: user.passwordHash,
        );
  }

  Future<bool> requiresFirstAdministratorSetup() {
    return _repository.hasActiveAdministrator().then((exists) => !exists);
  }

  /// Returns all users.
  Future<List<User>> getUsers() async {
    final entities = await _repository.getAllUsers();

    return entities.map((entity) => entity.toUser()).toList(growable: false);
  }

  /// Generic user finder.
  ///
  /// Any supplied parameter is used as a filter.
  /// If multiple parameters are supplied, they must all match.
  /// Returns active users with the specified role.
  ///
  /// This is used by features such as the inspection wizard
  /// to populate role-specific selectors without exposing
  /// inactive accounts.
  Future<List<User>> getUsersByRole(
    UserRole role, {
    bool activeOnly = true,
  }) async {
    final users = await getUsers();

    return users
        .where((user) => user.role == role && (!activeOnly || user.isActive))
        .toList(growable: false);
  }

  Future<User?> findUser({
    String? id,
    String? username,
    String? password,
    int? driverId,
    UserRole? role,
    bool? isActive,
  }) async {
    assert(
      id != null ||
          username != null ||
          password != null ||
          driverId != null ||
          role != null ||
          isActive != null,
      'At least one search parameter must be provided.',
    );

    final users = await getUsers();

    try {
      return users.firstWhere((user) {
        if (id != null && user.id != id) {
          return false;
        }

        if (username != null && user.username != username) {
          return false;
        }

        if (password != null &&
            !_passwordService.verify(
              plainTextPassword: password,
              storedValue: user.passwordHash,
            )) {
          return false;
        }

        if (driverId != null && user.driverId != driverId) {
          return false;
        }

        if (role != null && user.role != role) {
          return false;
        }

        if (isActive != null && user.isActive != isActive) {
          return false;
        }

        return true;
      });
    } on StateError {
      return null;
    }
  }

  Future<User?> getUserById(String id) async {
    final entity = await _repository.getUserById(id);

    return entity?.toUser();
  }

  Future<User?> getUserByUsername(String username) async {
    final entity = await _repository.getUserByUsername(username);

    return entity?.toUser();
  }

  Future<bool> isUsernameAvailable(
    String username, {
    String? excludingUserId,
  }) async {
    final existing = await getUserByUsername(username);
    return existing == null || existing.id == excludingUserId;
  }

  Future<User?> getUserByDriverId(int driverId) async {
    final entity = await _repository.getUserByDriverId(driverId);

    return entity?.toUser();
  }

  /// Adds a new user with a bcrypt password hash.
  Future<void> addUser(User user, {required String password}) async {
    _ensureDriverAccountIsLinked(user);
    _validateNewPassword(password);
    final userWithPasswordHash = user.copyWith(
      passwordHash: _passwordService.hash(password),
    );

    await _repository.insertUser(UserEntity.fromUser(userWithPasswordHash));
  }

  /// Atomically provisions the first usable Administrator.
  ///
  /// The persisted role, active flag and driver link are fixed here rather
  /// than trusting presentation-layer input.
  Future<bool> createFirstAdministrator(
    User user, {
    required String password,
  }) async {
    _validateNewPassword(password);
    final administrator = User(
      id: user.id,
      username: user.username,
      passwordHash: _passwordService.hash(password),
      role: UserRole.admin,
      isActive: true,
    );

    return _repository.insertFirstAdministrator(
      UserEntity.fromUser(administrator),
    );
  }

  /// Updates an existing user and only changes the stored password when a
  /// replacement plaintext password is supplied.
  Future<void> updateUser(User user, {String? newPassword}) async {
    _ensureDriverAccountIsLinked(user);
    if (newPassword != null) {
      _validateNewPassword(newPassword);
    }
    final userWithPasswordHash = newPassword == null
        ? user
        : user.copyWith(passwordHash: _passwordService.hash(newPassword));

    await _repository.updateUser(UserEntity.fromUser(userWithPasswordHash));
  }

  void _validateNewPassword(String password) {
    final message = PasswordPolicy.validate(password);
    if (message != null) {
      throw ArgumentError(message, 'password');
    }
  }

  /// Applies changes made through User Management while retaining the account
  /// and Driver lifecycle invariants enforced by that feature.
  Future<void> updateManagedUser(
    User user, {
    required String actingUserId,
    String? newPassword,
  }) async {
    final existing = await getUserById(user.id);
    if (existing == null) {
      throw UserManagementException('The user account no longer exists.');
    }

    if (existing.id == actingUserId &&
        (!user.isActive || user.role != existing.role)) {
      throw UserManagementException(
        'You cannot deactivate or change the role of your own account.',
      );
    }

    _ensureLinkedDriverUserRemainsManagedByDriver(existing, user);
    await _ensureActiveAdministratorIsRetained(existing, user);

    await updateUser(user, newPassword: newPassword);
  }

  /// Deletes an unlinked user from User Management only when doing so keeps
  /// an active Administrator available and does not remove the actor.
  Future<void> deleteManagedUser(
    String userId, {
    required String actingUserId,
  }) async {
    final existing = await getUserById(userId);
    if (existing == null) {
      throw UserManagementException('The user account no longer exists.');
    }

    if (existing.id == actingUserId) {
      throw UserManagementException('You cannot delete your own account.');
    }

    if (existing.driverId != null) {
      throw UserManagementException(
        'Driver-linked accounts are managed through Driver Management.',
      );
    }

    if (existing.role == UserRole.admin &&
        existing.isActive &&
        !await _repository.hasAnotherActiveAdministrator(existing.id)) {
      throw UserManagementException(
        'At least one active Administrator is required.',
      );
    }

    await _repository.deleteUser(existing.id);
  }

  void _ensureLinkedDriverUserRemainsManagedByDriver(
    User existing,
    User updated,
  ) {
    if (existing.driverId == null) return;

    final lifecycleChanged =
        updated.driverId != existing.driverId ||
        updated.username != existing.username ||
        updated.role != existing.role ||
        updated.isActive != existing.isActive;
    if (lifecycleChanged) {
      throw UserManagementException(
        'Driver-linked accounts are managed through Driver Management.',
      );
    }
  }

  Future<void> _ensureActiveAdministratorIsRetained(
    User existing,
    User updated,
  ) async {
    final remainsActiveAdministrator =
        updated.role == UserRole.admin && updated.isActive;
    if (existing.role == UserRole.admin &&
        existing.isActive &&
        !remainsActiveAdministrator &&
        !await _repository.hasAnotherActiveAdministrator(existing.id)) {
      throw UserManagementException(
        'At least one active Administrator is required.',
      );
    }
  }

  /// Saves a user.
  ///
  /// Updates an existing user if it already exists,
  /// otherwise creates a new one.
  Future<void> saveUser(User user) async {
    _ensureDriverAccountIsLinked(user);
    await _repository.saveUser(UserEntity.fromUser(user));
  }

  void _ensureDriverAccountIsLinked(User user) {
    if (user.role == UserRole.driver && user.driverId == null) {
      throw UserManagementException(
        'Driver accounts must be created from Driver Management.',
      );
    }
  }

  /// Deletes a user.
  Future<void> deleteUser(String id) async {
    await _repository.deleteUser(id);
  }
}

class UserManagementException implements Exception {
  const UserManagementException(this.message);

  final String message;

  @override
  String toString() => message;
}
