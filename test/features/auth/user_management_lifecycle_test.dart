import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/fake_security_audit_service.dart';

void main() {
  UserService service(_FakeUserRepository repository) => UserService(
    repository: repository,
    securityAuditService: FakeSecurityAuditService(),
  );

  test(
    'last active Administrator cannot be deactivated or role downgraded',
    () async {
      final users = _FakeUserRepository()..seed(_admin('admin-1'));
      final userService = service(users);

      await expectLater(
        userService.updateManagedUser(
          _admin('admin-1').copyWith(isActive: false),
          actingUserId: 'another-user',
        ),
        throwsA(isA<UserManagementException>()),
      );
      await expectLater(
        userService.updateManagedUser(
          _admin('admin-1').copyWith(role: UserRole.manager),
          actingUserId: 'another-user',
        ),
        throwsA(isA<UserManagementException>()),
      );
      expect((await userService.getUserById('admin-1'))!.isActive, isTrue);
      expect((await userService.getUserById('admin-1'))!.role, UserRole.admin);
    },
  );

  test('last active Administrator cannot be deleted', () async {
    final users = _FakeUserRepository()..seed(_admin('admin-1'));

    await expectLater(
      service(users).deleteManagedUser('admin-1', actingUserId: 'another-user'),
      throwsA(isA<UserManagementException>()),
    );
    expect(await service(users).getUserById('admin-1'), isNotNull);
  });

  test(
    'one Administrator may be changed or deleted when another remains',
    () async {
      final users = _FakeUserRepository()
        ..seed(_admin('admin-1'))
        ..seed(_admin('admin-2'))
        ..seed(_admin('admin-3'));
      final userService = service(users);

      await userService.updateManagedUser(
        _admin('admin-1').copyWith(role: UserRole.manager),
        actingUserId: 'admin-2',
      );
      await userService.deleteManagedUser(
        'admin-2',
        actingUserId: 'other-user',
      );

      expect(
        (await userService.getUserById('admin-1'))!.role,
        UserRole.manager,
      );
      expect(await userService.getUserById('admin-2'), isNull);
    },
  );

  test(
    'current User cannot deactivate, change role, or delete themselves',
    () async {
      final users = _FakeUserRepository()
        ..seed(_admin('admin-1'))
        ..seed(_admin('admin-2'));
      final userService = service(users);

      await expectLater(
        userService.updateManagedUser(
          _admin('admin-1').copyWith(isActive: false),
          actingUserId: 'admin-1',
        ),
        throwsA(isA<UserManagementException>()),
      );
      await expectLater(
        userService.updateManagedUser(
          _admin('admin-1').copyWith(role: UserRole.manager),
          actingUserId: 'admin-1',
        ),
        throwsA(isA<UserManagementException>()),
      );
      await expectLater(
        userService.deleteManagedUser('admin-1', actingUserId: 'admin-1'),
        throwsA(isA<UserManagementException>()),
      );
    },
  );

  test(
    'User Management cannot delete or change a Driver-linked account',
    () async {
      final users = _FakeUserRepository()..seed(_driverUser());
      final userService = service(users);

      await expectLater(
        userService.deleteManagedUser('driver-user', actingUserId: 'admin-1'),
        throwsA(isA<UserManagementException>()),
      );
      await expectLater(
        userService.updateManagedUser(
          _driverUser().copyWith(isActive: false),
          actingUserId: 'admin-1',
        ),
        throwsA(isA<UserManagementException>()),
      );
      await expectLater(
        userService.updateManagedUser(
          _driverUser().copyWith(role: UserRole.manager),
          actingUserId: 'admin-1',
        ),
        throwsA(isA<UserManagementException>()),
      );
    },
  );

  test('Driver synchronization can still deactivate its linked User', () async {
    final users = _FakeUserRepository()..seed(_driverUser());
    final userService = service(users);

    await userService.saveUser(_driverUser().copyWith(isActive: false));

    expect((await userService.getUserById('driver-user'))!.isActive, isFalse);
  });
}

User _admin(String id) =>
    User(id: id, username: id, passwordHash: 'hash', role: UserRole.admin);

User _driverUser() => const User(
  id: 'driver-user',
  username: 'driver.user',
  passwordHash: 'hash',
  role: UserRole.driver,
  driverId: 7,
);

class _FakeUserRepository extends UserRepository {
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor?) action) =>
      action(null);

  final _users = <String, UserEntity>{};

  void seed(User user) {
    _users[user.id] = UserEntity.fromUser(user);
  }

  @override
  Future<List<UserEntity>> getAllUsers() async => _users.values.toList();

  @override
  Future<UserEntity?> getUserById(String id) async => _users[id];

  @override
  Future<bool> hasAnotherActiveAdministrator(String excludedUserId) async =>
      _users.values.any(
        (user) =>
            user.id != excludedUserId &&
            user.role == UserRole.admin &&
            user.isActive,
      );

  @override
  Future<void> updateUser(UserEntity user, {Object? executor}) async {
    _users[user.id] = user;
  }

  @override
  Future<void> deleteUser(String id, {Object? executor}) async {
    _users.remove(id);
  }
}
