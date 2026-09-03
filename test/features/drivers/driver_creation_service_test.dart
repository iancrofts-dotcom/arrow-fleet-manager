import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_sync_service.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_creation_request.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_entity.dart';
import 'package:arrow_fleet_manager/features/drivers/repositories/driver_repository.dart';
import 'package:arrow_fleet_manager/features/drivers/services/driver_service.dart';
import 'package:arrow_fleet_manager/features/drivers/services/driver_username_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const passwords = PasswordService(workFactor: 4);

  UserService userService(_FakeUserRepository repository) =>
      UserService(repository: repository, passwordService: passwords);

  test(
    'creates a linked bcrypt user that authenticates with the submitted password',
    () async {
      final drivers = _FakeDriverRepository();
      final users = _FakeUserRepository();
      final driverUserService = userService(users);
      final service = DriverService(
        repository: drivers,
        userSyncService: UserSyncService(userService: driverUserService),
        usernameService: DriverUsernameService(userService: driverUserService),
      );

      final savedDriver = await service.addDriver(
        DriverCreationRequest(driver: _driver(), password: 'correct-password'),
      );
      final linkedUser = users.userForDriver(savedDriver.id!);

      expect(savedDriver.id, 1);
      expect(linkedUser, isNotNull);
      expect(linkedUser!.role, UserRole.driver);
      expect(linkedUser.driverId, savedDriver.id);
      expect(savedDriver.username, 'alex.driver');
      expect(linkedUser.username, savedDriver.username);
      expect(linkedUser.passwordHash, isNot('correct-password'));
      expect(passwords.isSecureHash(linkedUser.passwordHash), isTrue);
      expect(
        await driverUserService.login(
          username: 'alex.driver',
          password: 'correct-password',
        ),
        isNotNull,
      );
      expect(
        await driverUserService.login(
          username: 'alex.driver',
          password: 'incorrect-password',
        ),
        isNull,
      );
    },
  );

  test('returns exact IDs for duplicate-looking driver inserts', () async {
    final drivers = _FakeDriverRepository();
    final users = _FakeUserRepository();
    final driverUserService = userService(users);
    final service = DriverService(
      repository: drivers,
      userSyncService: UserSyncService(userService: driverUserService),
      usernameService: DriverUsernameService(userService: driverUserService),
    );

    final first = await service.addDriver(
      DriverCreationRequest(driver: _driver(), password: 'password-one'),
    );
    final second = await service.addDriver(
      DriverCreationRequest(driver: _driver(), password: 'password-two'),
    );

    expect(first.id, 1);
    expect(second.id, 2);
    expect(first.firstName, second.firstName);
    expect(first.lastName, second.lastName);
    expect(first.licenceNumber, second.licenceNumber);
    expect(first.username, 'alex.driver');
    expect(second.username, 'alex.driver2');
  });

  test(
    'removes only the newly inserted driver when linked user creation fails',
    () async {
      final drivers = _FakeDriverRepository();
      final users = _FakeUserRepository();
      drivers.seed(_driver(id: 1, username: 'existing.driver'));
      final service = DriverService(
        repository: drivers,
        userSyncService: _FailingUserSyncService(),
        usernameService: DriverUsernameService(userService: userService(users)),
      );

      await expectLater(
        service.addDriver(
          DriverCreationRequest(
            driver: _driver(),
            password: 'correct-password',
          ),
        ),
        throwsStateError,
      );

      expect(drivers.driverIds, {1});
    },
  );

  test('sync preserves an existing linked user bcrypt password hash', () async {
    final users = _FakeUserRepository();
    final service = userService(users);
    final passwordHash = passwords.hash('existing-password');
    users.seed(
      User(
        id: 'user-1',
        username: 'driver.one',
        passwordHash: passwordHash,
        role: UserRole.driver,
        driverId: 1,
      ),
    );
    final sync = UserSyncService(userService: service);

    await sync.syncDriver(
      _driver(id: 1, username: 'driver.renamed', isActive: false),
    );
    final updatedUser = users.userForDriver(1);

    expect(updatedUser!.username, 'driver.renamed');
    expect(updatedUser.passwordHash, passwordHash);
    expect(updatedUser.isActive, isFalse);
    expect(
      await service.login(
        username: 'driver.renamed',
        password: 'existing-password',
      ),
      isNull,
    );
  });

  test('generates the base username when no persisted User has it', () async {
    final users = _FakeUserRepository();
    final generator = DriverUsernameService(userService: userService(users));

    expect(
      await generator.generateUsername(firstName: 'Ian', lastName: 'Crofts'),
      'ian.crofts',
    );
  });

  test(
    'generates the next available username after existing candidates',
    () async {
      final users = _FakeUserRepository()..seed(_user('ian.crofts'));
      final generator = DriverUsernameService(userService: userService(users));

      expect(
        await generator.generateUsername(firstName: 'Ian', lastName: 'Crofts'),
        'ian.crofts2',
      );

      users.seed(_user('ian.crofts2'));
      expect(
        await generator.generateUsername(firstName: 'Ian', lastName: 'Crofts'),
        'ian.crofts3',
      );
    },
  );

  test('fills the first available username suffix gap', () async {
    final users = _FakeUserRepository()
      ..seed(_user('ian.crofts'))
      ..seed(_user('ian.crofts2'))
      ..seed(_user('ian.crofts4'));
    final generator = DriverUsernameService(userService: userService(users));

    expect(
      await generator.generateUsername(firstName: 'Ian', lastName: 'Crofts'),
      'ian.crofts3',
    );
  });

  test('normalizes whitespace and case in generated usernames', () async {
    final users = _FakeUserRepository();
    final generator = DriverUsernameService(userService: userService(users));

    expect(
      await generator.generateUsername(
        firstName: '  Mary   Jane ',
        lastName: ' SMITH  ',
      ),
      'maryjane.smith',
    );
  });
}

class _FakeDriverRepository extends DriverRepository {
  final _drivers = <int, DriverEntity>{};
  var _nextId = 1;

  Set<int> get driverIds => _drivers.keys.toSet();

  void seed(Driver driver) {
    final id = driver.id!;
    _drivers[id] = DriverEntity.fromDriver(driver);
    _nextId = id + 1;
  }

  @override
  Future<int> insertDriver(DriverEntity driver) async {
    final id = _nextId++;
    _drivers[id] = DriverEntity(
      id: id,
      firstName: driver.firstName,
      lastName: driver.lastName,
      licenceNumber: driver.licenceNumber,
      licenceExpiry: driver.licenceExpiry,
      phone: driver.phone,
      email: driver.email,
      username: driver.username,
      isActive: driver.isActive,
    );
    return id;
  }

  @override
  Future<DriverEntity?> getDriverById(int id) async => _drivers[id];

  @override
  Future<int> deleteDriver(int id) async => _drivers.remove(id) == null ? 0 : 1;
}

class _FakeUserRepository extends UserRepository {
  final _users = <String, UserEntity>{};

  void seed(User user) {
    _users[user.id] = UserEntity.fromUser(user);
  }

  User? userForDriver(int driverId) {
    for (final user in _users.values) {
      if (user.driverId == driverId) return user.toUser();
    }
    return null;
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
  Future<UserEntity?> getUserByDriverId(int driverId) async {
    for (final user in _users.values) {
      if (user.driverId == driverId) return user;
    }
    return null;
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

class _FailingUserSyncService extends UserSyncService {
  @override
  Future<void> createDriverUser(
    Driver driver, {
    required String password,
  }) async {
    throw StateError('User creation failed.');
  }
}

User _user(String username) => User(
  id: 'user-$username',
  username: username,
  passwordHash: 'hash',
  role: UserRole.driver,
  driverId: 99,
);

Driver _driver({int? id, String? username, bool isActive = true}) => Driver(
  id: id,
  firstName: 'Alex',
  lastName: 'Driver',
  licenceNumber: 'LIC-100',
  username: username,
  isActive: isActive,
);
