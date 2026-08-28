import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_initializer.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const passwords = PasswordService(workFactor: 4);

  UserService service(_FakeUserRepository repository) =>
      UserService(repository: repository, passwordService: passwords);

  test('fresh database requires setup and creates no default users', () async {
    final users = _FakeUserRepository();
    final initializer = AuthInitializer(userService: service(users));

    expect(await initializer.requiresFirstAdministratorSetup(), isTrue);
    expect(await service(users).getUserByUsername('admin'), isNull);
    expect(await service(users).getUserByUsername('manager'), isNull);
  });

  test(
    'first Administrator is active, bcrypt protected, and authenticates',
    () async {
      final users = _FakeUserRepository();
      final userService = service(users);
      final created = await userService.createFirstAdministrator(
        const User(
          id: 'first-admin',
          username: 'operations.admin',
          passwordHash: '',
          role: UserRole.driver,
          driverId: 99,
          isActive: false,
        ),
        password: 'chosen-password',
      );

      final administrator = await userService.getUserById('first-admin');
      expect(created, isTrue);
      expect(administrator, isNotNull);
      expect(administrator!.role, UserRole.admin);
      expect(administrator.isActive, isTrue);
      expect(administrator.driverId, isNull);
      expect(administrator.passwordHash, isNot('chosen-password'));
      expect(passwords.isSecureHash(administrator.passwordHash), isTrue);
      expect(
        await userService.login(
          username: 'operations.admin',
          password: 'chosen-password',
        ),
        isNotNull,
      );
      expect(
        await userService.login(
          username: 'operations.admin',
          password: 'wrong-password',
        ),
        isNull,
      );
      expect(await userService.requiresFirstAdministratorSetup(), isFalse);
    },
  );

  test('users and inactive Administrators do not complete bootstrap', () async {
    final users = _FakeUserRepository();
    users.seed(_user('driver-user', UserRole.driver));
    users.seed(_user('inactive-admin', UserRole.admin, isActive: false));

    expect(await service(users).requiresFirstAdministratorSetup(), isTrue);
  });

  test(
    'first-run creation cannot create another Administrator after completion',
    () async {
      final users = _FakeUserRepository();
      final userService = service(users);
      final first = await userService.createFirstAdministrator(
        _user('first', UserRole.admin),
        password: 'password-one',
      );
      final second = await userService.createFirstAdministrator(
        _user('second', UserRole.admin),
        password: 'password-two',
      );

      expect(first, isTrue);
      expect(second, isFalse);
      expect(
        (await userService.getUsers()).where((u) => u.role == UserRole.admin),
        hasLength(1),
      );
    },
  );

  test(
    'duplicate bootstrap username fails without changing the existing user',
    () async {
      final users = _FakeUserRepository();
      final existing = _user('existing-user', UserRole.driver);
      users.seed(existing);
      final userService = service(users);

      await expectLater(
        userService.createFirstAdministrator(
          const User(
            id: 'administrator',
            username: 'existing-user',
            passwordHash: '',
            role: UserRole.admin,
          ),
          password: 'new-password',
        ),
        throwsStateError,
      );

      expect(await userService.getUserById(existing.id), existing);
      expect(await userService.requiresFirstAdministratorSetup(), isTrue);
    },
  );

  test(
    'legacy seed detection occurs before migration and clears after change',
    () async {
      final users = _FakeUserRepository();
      users.seed(
        const User(
          id: 'admin',
          username: 'admin',
          passwordHash: 'admin',
          role: UserRole.admin,
        ),
      );
      final userService = service(users);

      final seeded = await userService.login(
        username: 'admin',
        password: 'admin',
      );
      expect(seeded, isNotNull);
      expect(userService.requiresPasswordChange(seeded!), isTrue);
      expect((await userService.getUserById('admin'))!.passwordHash, 'admin');

      await userService.updateUser(seeded, newPassword: 'replacement-password');
      final changed = await userService.getUserById('admin');
      expect(changed!.passwordHash, isNot('replacement-password'));
      expect(passwords.isSecureHash(changed.passwordHash), isTrue);
      expect(userService.requiresPasswordChange(changed), isFalse);
      expect(
        await userService.login(username: 'admin', password: 'admin'),
        isNull,
      );
      expect(
        await userService.login(
          username: 'admin',
          password: 'replacement-password',
        ),
        isNotNull,
      );
    },
  );

  test(
    'same historical username with a changed password is not flagged',
    () async {
      final users = _FakeUserRepository();
      final userService = service(users);
      await userService.addUser(
        _user('admin', UserRole.admin),
        password: 'not-the-seeded-password',
      );

      final user = await userService.getUserById('admin');
      expect(userService.requiresPasswordChange(user!), isFalse);
    },
  );

  test(
    'legacy manager seed is detected only while its password is unchanged',
    () async {
      final users = _FakeUserRepository();
      final userService = service(users);
      users.seed(
        const User(
          id: 'manager',
          username: 'manager',
          passwordHash: '',
          role: UserRole.manager,
        ).copyWith(passwordHash: passwords.hash('manager')),
      );

      final seededManager = await userService.getUserById('manager');
      expect(userService.requiresPasswordChange(seededManager!), isTrue);

      await userService.updateUser(
        seededManager,
        newPassword: 'manager-replacement',
      );
      expect(
        userService.requiresPasswordChange(
          (await userService.getUserById('manager'))!,
        ),
        isFalse,
      );
    },
  );
}

User _user(String id, UserRole role, {bool isActive = true}) => User(
  id: id,
  username: id,
  passwordHash: 'stored-password',
  role: role,
  isActive: isActive,
);

class _FakeUserRepository extends UserRepository {
  final _users = <String, UserEntity>{};

  void seed(User user) {
    _users[user.id] = UserEntity.fromUser(user);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async => _users.values.toList();

  @override
  Future<UserEntity?> getUserById(String id) async => _users[id];

  @override
  Future<UserEntity?> getUserByUsername(String username) async {
    for (final user in _users.values) {
      if (user.username == username) return user;
    }
    return null;
  }

  @override
  Future<bool> hasActiveAdministrator() async =>
      _users.values.any((user) => user.role == UserRole.admin && user.isActive);

  @override
  Future<bool> insertFirstAdministrator(UserEntity user) async {
    if (await hasActiveAdministrator()) return false;
    if (await getUserByUsername(user.username) != null) {
      throw StateError('Username already exists.');
    }
    _users[user.id] = user;
    return true;
  }

  @override
  Future<void> insertUser(UserEntity user) async {
    if (await getUserByUsername(user.username) != null) {
      throw StateError('Username already exists.');
    }
    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    _users[user.id] = user;
  }
}
