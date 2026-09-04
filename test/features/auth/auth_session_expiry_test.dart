import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
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
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 1, 9);
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
      now: () => now,
      enableSessionWatchdog: false,
    );
  });

  tearDown(() => auth.dispose());

  Future<void> signIn() async {
    await userService.addUser(_user(), password: 'password');
    expect(await auth.login(username: 'user-1', password: 'password'), isTrue);
  }

  Future<void> registerActivityBeforeAbsoluteExpiry() async {
    final authenticatedAt = auth.authenticatedAt!;
    final target = authenticatedAt.add(
      AuthService.absoluteTimeout - const Duration(minutes: 1),
    );

    while (now.add(const Duration(minutes: 59)).isBefore(target)) {
      now = now.add(const Duration(minutes: 59));
      await auth.registerActivity();
    }

    now = target;
    await auth.registerActivity();
  }

  test(
    'successful login initializes both session timestamps together',
    () async {
      await signIn();

      expect(auth.authenticatedAt, now);
      expect(auth.lastActivityAt, now);
    },
  );

  test('failed login does not create session metadata', () async {
    users.seed(_user(passwordHash: passwords.hash('password')));

    expect(await auth.login(username: 'user-1', password: 'wrong'), isFalse);
    expect(auth.authenticatedAt, isNull);
    expect(auth.lastActivityAt, isNull);
    expect(auth.currentUser, isNull);
  });

  test('activity before idle expiry updates only last activity', () async {
    await signIn();
    final authenticatedAt = auth.authenticatedAt;
    now = now.add(const Duration(minutes: 59));

    await auth.registerActivity();

    expect(auth.authenticatedAt, authenticatedAt);
    expect(auth.lastActivityAt, now);
    expect(await auth.evaluateSessionExpiry(), SessionExpiryStatus.valid);
  });

  test('exactly 60 minutes idle expires and clears the session', () async {
    await signIn();
    now = now.add(AuthService.idleTimeout);

    expect(await auth.evaluateSessionExpiry(), SessionExpiryStatus.expired);
    await _expectSessionCleared(auth, sessions);
  });

  test('more than 60 minutes idle expires the session', () async {
    await signIn();
    now = now.add(AuthService.idleTimeout + const Duration(seconds: 1));

    expect(await auth.evaluateSessionExpiry(), SessionExpiryStatus.expired);
    await _expectSessionCleared(auth, sessions);
  });

  test('activity at 59 minutes keeps the session valid', () async {
    await signIn();
    now = now.add(const Duration(minutes: 59));

    await auth.registerActivity();

    expect(await auth.evaluateSessionExpiry(), SessionExpiryStatus.valid);
    expect(auth.currentUser, isNotNull);
  });

  test('absolute expiry wins even after recent activity', () async {
    await signIn();
    final authenticatedAt = auth.authenticatedAt!;
    await registerActivityBeforeAbsoluteExpiry();
    expect(
      auth.lastActivityAt,
      authenticatedAt.add(
        AuthService.absoluteTimeout - const Duration(minutes: 1),
      ),
    );
    now = authenticatedAt.add(AuthService.absoluteTimeout);

    expect(await auth.evaluateSessionExpiry(), SessionExpiryStatus.expired);
    await _expectSessionCleared(auth, sessions);
  });

  test('activity cannot extend the absolute session lifetime', () async {
    await signIn();
    final authenticatedAt = auth.authenticatedAt!;
    await registerActivityBeforeAbsoluteExpiry();
    expect(auth.authenticatedAt, authenticatedAt);
    expect(
      auth.lastActivityAt,
      authenticatedAt.add(
        AuthService.absoluteTimeout - const Duration(minutes: 1),
      ),
    );

    now = authenticatedAt.add(AuthService.absoluteTimeout);

    expect(await auth.evaluateSessionExpiry(), SessionExpiryStatus.expired);

    await _expectSessionCleared(auth, sessions);
  });

  test('logout clears in-memory session metadata', () async {
    await signIn();

    await auth.logout();

    await _expectSessionCleared(auth, sessions);
  });

  test('revalidation refreshes a changed persisted driver link', () async {
    await signIn();
    users.seed(auth.currentUser!.copyWith(driverId: 42));

    expect(
      await auth.revalidateCurrentSession(),
      SessionValidationResult.authenticated,
    );
    expect(auth.currentDriverId, 42);
  });

  test(
    'legacy persisted user IDs cannot restore a session after restart',
    () async {
      await userService.addUser(_user(), password: 'password');
      await sessions.saveUserId('user-1');
      final restartedAuth = AuthService(
        userService: userService,
        sessionService: sessions,
        now: () => now,
        enableSessionWatchdog: false,
      );
      addTearDown(restartedAuth.dispose);

      expect(await restartedAuth.restoreSession(), isFalse);
      expect(restartedAuth.currentUser, isNull);
      expect(await sessions.getUserId(), isNull);
    },
  );

  test('auth-state notifications occur for login and logout', () async {
    var notifications = 0;
    auth.addListener(() => notifications++);

    await signIn();
    await auth.logout();

    expect(notifications, 2);
  });

  test('ordinary activity does not notify auth-state listeners', () async {
    await signIn();
    var notifications = 0;
    auth.addListener(() => notifications++);
    now = now.add(const Duration(minutes: 1));

    await auth.registerActivity();

    expect(notifications, 0);
  });
}

User _user({String passwordHash = ''}) => User(
  id: 'user-1',
  username: 'user-1',
  passwordHash: passwordHash,
  role: UserRole.manager,
);

Future<void> _expectSessionCleared(
  AuthService auth,
  SessionService sessions,
) async {
  expect(auth.currentUser, isNull);
  expect(auth.authenticatedAt, isNull);
  expect(auth.lastActivityAt, isNull);
  expect(await sessions.getUserId(), isNull);
}

class _FakeUserRepository extends UserRepository {
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor?) action) =>
      action(null);

  final _users = <String, UserEntity>{};

  void seed(User user) {
    _users[user.id] = UserEntity.fromUser(user);
  }

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
  Future<void> insertUser(UserEntity user, {Object? executor}) async {
    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserEntity user, {Object? executor}) async {
    _users[user.id] = user;
  }
}
