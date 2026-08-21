import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_sync_service.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_entity.dart';
import 'package:arrow_fleet_manager/features/drivers/repositories/driver_repository.dart';
import 'package:arrow_fleet_manager/features/drivers/services/driver_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const passwords = PasswordService(workFactor: 4);

  _Harness harness() => _Harness(passwords: passwords);

  test(
    'My Account username changes keep the linked Driver synchronized',
    () async {
      final testHarness = harness();
      final originalHash = passwords.hash('existing-password');
      testHarness.seedLinkedAccount(passwordHash: originalHash);

      await testHarness.driverService.updateDriverLinkedAccount(
        testHarness.linkedUser,
        username: 'driver.renamed',
      );

      final driver = testHarness.drivers.driver(1)!;
      final user = await testHarness.userService.getUserById('driver-user');
      expect(driver.id, 1);
      expect(driver.username, 'driver.renamed');
      expect(user!.id, 'driver-user');
      expect(user.driverId, 1);
      expect(user.username, 'driver.renamed');
      expect(user.passwordHash, originalHash);
    },
  );

  test(
    'later Driver edits do not revert a My Account username change',
    () async {
      final testHarness = harness();
      testHarness.seedLinkedAccount(passwordHash: passwords.hash('password'));

      await testHarness.driverService.updateDriverLinkedAccount(
        testHarness.linkedUser,
        username: 'driver.renamed',
      );
      await testHarness.driverService.updateDriver(
        testHarness.drivers.driver(1)!.copyWith(phone: '01234 567890'),
      );

      expect(testHarness.drivers.driver(1)!.username, 'driver.renamed');
      expect(
        (await testHarness.userService.getUserById('driver-user'))!.username,
        'driver.renamed',
      );
    },
  );

  test('username collision leaves both linked records unchanged', () async {
    final testHarness = harness();
    testHarness.seedLinkedAccount(passwordHash: passwords.hash('password'));
    testHarness.users.seed(
      const User(
        id: 'other-user',
        username: 'taken.username',
        passwordHash: 'hash',
        role: UserRole.manager,
      ),
    );

    await expectLater(
      testHarness.driverService.updateDriverLinkedAccount(
        testHarness.linkedUser,
        username: 'taken.username',
      ),
      throwsStateError,
    );

    expect(testHarness.drivers.driver(1)!.username, 'driver.original');
    expect(
      (await testHarness.userService.getUserById('driver-user'))!.username,
      'driver.original',
    );
  });

  test('missing linked Driver fails without changing the User', () async {
    final testHarness = harness();
    testHarness.users.seed(testHarness.linkedUser);

    await expectLater(
      testHarness.driverService.updateDriverLinkedAccount(
        testHarness.linkedUser,
        username: 'driver.renamed',
      ),
      throwsStateError,
    );

    expect(
      (await testHarness.userService.getUserById('driver-user'))!.username,
      'driver.original',
    );
  });

  test(
    'failed linked User write restores the original Driver username',
    () async {
      final testHarness = harness();
      testHarness.seedLinkedAccount(passwordHash: passwords.hash('password'));
      testHarness.users.failUpdates = true;

      await expectLater(
        testHarness.driverService.updateDriverLinkedAccount(
          testHarness.linkedUser,
          username: 'driver.renamed',
        ),
        throwsStateError,
      );

      expect(testHarness.drivers.driver(1)!.username, 'driver.original');
      expect(
        (await testHarness.userService.getUserById('driver-user'))!.username,
        'driver.original',
      );
    },
  );

  test(
    'username-only linked account changes preserve bcrypt authentication',
    () async {
      final testHarness = harness();
      final passwordHash = passwords.hash('existing-password');
      testHarness.seedLinkedAccount(passwordHash: passwordHash);

      await testHarness.driverService.updateDriverLinkedAccount(
        testHarness.linkedUser,
        username: 'driver.renamed',
      );

      final savedUser = await testHarness.userService.getUserById(
        'driver-user',
      );
      expect(savedUser!.passwordHash, passwordHash);
      expect(
        await testHarness.userService.login(
          username: 'driver.renamed',
          password: 'existing-password',
        ),
        isNotNull,
      );
    },
  );

  test(
    'linked account username and password changes use the new credentials',
    () async {
      final testHarness = harness();
      testHarness.seedLinkedAccount(
        passwordHash: passwords.hash('old-password'),
      );

      await testHarness.driverService.updateDriverLinkedAccount(
        testHarness.linkedUser,
        username: 'driver.renamed',
        newPassword: 'new-password',
      );

      final savedUser = await testHarness.userService.getUserById(
        'driver-user',
      );
      expect(savedUser!.passwordHash, isNot('new-password'));
      expect(passwords.isSecureHash(savedUser.passwordHash), isTrue);
      expect(
        await testHarness.userService.login(
          username: 'driver.renamed',
          password: 'new-password',
        ),
        isNotNull,
      );
      expect(
        await testHarness.userService.login(
          username: 'driver.original',
          password: 'new-password',
        ),
        isNull,
      );
      expect(
        await testHarness.userService.login(
          username: 'driver.renamed',
          password: 'old-password',
        ),
        isNull,
      );
    },
  );

  test(
    'ordinary non-Driver account updates remain independent of Drivers',
    () async {
      final testHarness = harness();
      const user = User(
        id: 'manager-user',
        username: 'manager.original',
        passwordHash: 'hash',
        role: UserRole.manager,
      );
      testHarness.users.seed(user);

      await testHarness.userService.updateUser(
        user.copyWith(username: 'manager.renamed'),
      );

      expect(
        (await testHarness.userService.getUserById('manager-user'))!.username,
        'manager.renamed',
      );
      expect(testHarness.drivers.driver(1), isNull);
    },
  );
}

class _Harness {
  _Harness({required PasswordService passwords}) {
    userService = UserService(repository: users, passwordService: passwords);
    driverService = DriverService(
      repository: drivers,
      userService: userService,
      userSyncService: UserSyncService(userService: userService),
    );
  }

  final _FakeDriverRepository drivers = _FakeDriverRepository();
  final _FakeUserRepository users = _FakeUserRepository();
  late final DriverService driverService;
  late final UserService userService;

  User get linkedUser => const User(
    id: 'driver-user',
    username: 'driver.original',
    passwordHash: 'unused',
    role: UserRole.driver,
    driverId: 1,
  );

  void seedLinkedAccount({required String passwordHash}) {
    drivers.seed(_driver());
    users.seed(linkedUser.copyWith(passwordHash: passwordHash));
  }
}

class _FakeDriverRepository extends DriverRepository {
  final _drivers = <int, DriverEntity>{};

  void seed(Driver driver) {
    _drivers[driver.id!] = DriverEntity.fromDriver(driver);
  }

  Driver? driver(int id) => _drivers[id]?.toDriver();

  @override
  Future<DriverEntity?> getDriverById(int id) async => _drivers[id];

  @override
  Future<int> updateDriver(DriverEntity driver) async {
    if (driver.id == null || !_drivers.containsKey(driver.id)) return 0;
    _drivers[driver.id!] = driver;
    return 1;
  }
}

class _FakeUserRepository extends UserRepository {
  final _users = <String, UserEntity>{};
  bool failUpdates = false;

  void seed(User user) => _users[user.id] = UserEntity.fromUser(user);

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
  Future<void> updateUser(UserEntity user) async {
    if (failUpdates) throw StateError('User write failed.');
    _users[user.id] = user;
  }
}

Driver _driver() => const Driver(
  id: 1,
  firstName: 'Alex',
  lastName: 'Driver',
  licenceNumber: 'LIC-100',
  username: 'driver.original',
);
