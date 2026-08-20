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
      final service = DriverService(
        repository: drivers,
        userSyncService: UserSyncService(userService: userService(users)),
      );

      final savedDriver = await service.addDriver(
        DriverCreationRequest(
          driver: _driver(username: 'driver.one'),
          password: 'correct-password',
        ),
      );
      final linkedUser = users.userForDriver(savedDriver.id!);

      expect(savedDriver.id, 1);
      expect(linkedUser, isNotNull);
      expect(linkedUser!.driverId, savedDriver.id);
      expect(linkedUser.passwordHash, isNot('correct-password'));
      expect(passwords.isSecureHash(linkedUser.passwordHash), isTrue);
      expect(
        await userService(
          users,
        ).login(username: 'driver.one', password: 'correct-password'),
        isNotNull,
      );
      expect(
        await userService(
          users,
        ).login(username: 'driver.one', password: 'incorrect-password'),
        isNull,
      );
    },
  );

  test('returns exact IDs for duplicate-looking driver inserts', () async {
    final drivers = _FakeDriverRepository();
    final service = DriverService(
      repository: drivers,
      userSyncService: _RecordingUserSyncService(),
    );

    final first = await service.addDriver(
      DriverCreationRequest(
        driver: _driver(username: 'driver.one'),
        password: 'password-one',
      ),
    );
    final second = await service.addDriver(
      DriverCreationRequest(
        driver: _driver(username: 'driver.two'),
        password: 'password-two',
      ),
    );

    expect(first.id, 1);
    expect(second.id, 2);
    expect(first.firstName, second.firstName);
    expect(first.lastName, second.lastName);
    expect(first.licenceNumber, second.licenceNumber);
    expect(first.username, 'driver.one');
    expect(second.username, 'driver.two');
  });

  test(
    'removes only the newly inserted driver when linked user creation fails',
    () async {
      final drivers = _FakeDriverRepository();
      drivers.seed(_driver(id: 1, username: 'existing.driver'));
      final service = DriverService(
        repository: drivers,
        userSyncService: _FailingUserSyncService(),
      );

      await expectLater(
        service.addDriver(
          DriverCreationRequest(
            driver: _driver(username: 'driver.one'),
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

class _RecordingUserSyncService extends UserSyncService {
  @override
  Future<bool> isUsernameInUse(String username) async => false;

  @override
  Future<void> createDriverUser(
    Driver driver, {
    required String password,
  }) async {}
}

class _FailingUserSyncService extends _RecordingUserSyncService {
  @override
  Future<void> createDriverUser(
    Driver driver, {
    required String password,
  }) async {
    throw StateError('User creation failed.');
  }
}

Driver _driver({int? id, required String username, bool isActive = true}) =>
    Driver(
      id: id,
      firstName: 'Alex',
      lastName: 'Driver',
      licenceNumber: 'LIC-100',
      username: username,
      isActive: isActive,
    );
