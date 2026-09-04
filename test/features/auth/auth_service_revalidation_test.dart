import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/permissions.dart';
import 'package:arrow_fleet_manager/features/auth/services/session_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_security_audit_service.dart';

void main() {
  const passwords = PasswordService(workFactor: 4);

  late _FakeUserRepository users;
  late UserService userService;
  late SessionService sessions;
  late AuthService auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    users = _FakeUserRepository();
    userService = UserService(
      repository: users,
      passwordService: passwords,
      securityAuditService: FakeSecurityAuditService(),
    );
    sessions = SessionService();
    auth = AuthService(
      userService: userService,
      sessionService: sessions,
      enableSessionWatchdog: false,
    );
  });

  Future<void> signIn(User user, {String password = 'password'}) async {
    await userService.addUser(user, password: password);
    expect(
      await auth.login(username: user.username, password: password),
      isTrue,
    );
  }

  test(
    'role downgrade refreshes the cached User and removes prior access',
    () async {
      await signIn(_user('manager', UserRole.manager));
      await userService.updateUser(
        auth.currentUser!.copyWith(role: UserRole.technician),
      );

      final result = await auth.revalidateCurrentSession();

      expect(result, SessionValidationResult.authenticated);
      expect(auth.currentUser!.role, UserRole.technician);
      expect(auth.currentRole, UserRole.technician);
    },
  );

  test(
    'revalidation removes Fleet Report access after a persisted role downgrade',
    () async {
      await signIn(_user('manager', UserRole.manager));
      await userService.updateUser(
        auth.currentUser!.copyWith(role: UserRole.technician),
      );

      expect(
        await auth.revalidateCurrentSession(),
        SessionValidationResult.authenticated,
      );
      expect(Permissions.canViewReports(auth.currentUser), isFalse);
    },
  );

  test(
    'revalidation removes Workshop Report access after a persisted role change',
    () async {
      await signIn(_user('workshop', UserRole.workshop));
      await userService.updateUser(
        auth.currentUser!.copyWith(role: UserRole.technician),
      );

      expect(
        await auth.revalidateCurrentSession(),
        SessionValidationResult.authenticated,
      );
      expect(Permissions.canManageRepairs(auth.currentUser), isFalse);
    },
  );

  test(
    'revalidation removes vehicle management after a persisted role change',
    () async {
      await signIn(_user('manager', UserRole.manager));
      await userService.updateUser(
        auth.currentUser!.copyWith(role: UserRole.workshop),
      );

      expect(
        await auth.revalidateCurrentSession(),
        SessionValidationResult.authenticated,
      );
      expect(Permissions.canManageFleet(auth.currentUser), isFalse);
    },
  );

  test(
    'revalidation removes driver management after a persisted role change',
    () async {
      await signIn(_user('manager', UserRole.manager));
      await userService.updateUser(
        auth.currentUser!.copyWith(role: UserRole.workshop),
      );

      expect(
        await auth.revalidateCurrentSession(),
        SessionValidationResult.authenticated,
      );
      expect(Permissions.canManageDrivers(auth.currentUser), isFalse);
    },
  );

  test(
    'revalidation removes User Management after a persisted role change',
    () async {
      await signIn(_user('admin', UserRole.admin));
      await userService.updateUser(
        auth.currentUser!.copyWith(role: UserRole.manager),
      );

      expect(
        await auth.revalidateCurrentSession(),
        SessionValidationResult.authenticated,
      );
      expect(Permissions.canManageUsers(auth.currentUser), isFalse);
    },
  );

  test('inactive persisted User invalidates the running session', () async {
    await signIn(_user('user-1', UserRole.manager));
    await userService.updateUser(auth.currentUser!.copyWith(isActive: false));

    expect(
      await auth.revalidateCurrentSession(),
      SessionValidationResult.unauthenticated,
    );
    expect(auth.currentUser, isNull);
    expect(await sessions.getUserId(), isNull);
  });

  test('deleted persisted User invalidates the running session', () async {
    await signIn(_user('user-1', UserRole.manager));
    users.remove('user-1');

    expect(
      await auth.revalidateCurrentSession(),
      SessionValidationResult.unauthenticated,
    );
    expect(auth.currentUser, isNull);
    expect(await sessions.getUserId(), isNull);
  });

  test('unchanged active User retains their session', () async {
    await signIn(_user('user-1', UserRole.manager));

    expect(
      await auth.revalidateCurrentSession(),
      SessionValidationResult.authenticated,
    );
    expect(auth.currentUser!.id, 'user-1');
    expect(await sessions.getUserId(), 'user-1');
  });

  test(
    'Driver-linked User deactivation uses the same revocation path',
    () async {
      await signIn(_user('driver-user', UserRole.driver, driverId: 7));
      await userService.saveUser(auth.currentUser!.copyWith(isActive: false));

      expect(
        await auth.revalidateCurrentSession(),
        SessionValidationResult.unauthenticated,
      );
      expect(auth.currentUser, isNull);
    },
  );

  test(
    'refresh failure retains session state but reports fail-closed result',
    () async {
      await signIn(_user('user-1', UserRole.manager));
      users.failReads = true;

      expect(
        await auth.revalidateCurrentSession(),
        SessionValidationResult.refreshFailed,
      );
      expect(auth.currentUser!.id, 'user-1');
      expect(await sessions.getUserId(), 'user-1');
    },
  );

  test('legacy seeded password requirement survives revalidation', () async {
    users.seed(
      User(
        id: 'admin',
        username: 'admin',
        passwordHash: passwords.hash('admin'),
        role: UserRole.admin,
      ),
    );

    expect(await auth.login(username: 'admin', password: 'admin'), isTrue);
    expect(auth.requiresPasswordChange, isTrue);
    expect(
      await auth.revalidateCurrentSession(),
      SessionValidationResult.authenticated,
    );
    expect(auth.requiresPasswordChange, isTrue);
  });
}

User _user(String id, UserRole role, {int? driverId, bool isActive = true}) =>
    User(
      id: id,
      username: id,
      passwordHash: '',
      role: role,
      driverId: driverId,
      isActive: isActive,
    );

class _FakeUserRepository extends UserRepository {
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor?) action) =>
      action(null);

  final _users = <String, UserEntity>{};
  bool failReads = false;

  void seed(User user) {
    _users[user.id] = UserEntity.fromUser(user);
  }

  void remove(String id) {
    _users.remove(id);
  }

  @override
  Future<UserEntity?> getUserById(String id) async {
    if (failReads) throw StateError('Database unavailable');
    return _users[id];
  }

  @override
  Future<UserEntity?> getUserByUsername(String username) async {
    for (final user in _users.values) {
      if (user.username == username) return user;
    }
    return null;
  }

  @override
  Future<void> insertUser(UserEntity user, {Object? executor}) async {
    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserEntity user, {Object? executor}) async {
    _users[user.id] = user;
  }
}
