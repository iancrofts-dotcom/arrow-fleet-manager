import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/screens/login_screen.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/session_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:arrow_fleet_manager/features/auth/widgets/session_activity_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_security_audit_service.dart';

void main() {
  const passwords = PasswordService(workFactor: 4);

  late _FakeUserRepository users;
  late UserService userService;
  late AuthService auth;
  late DateTime now;
  late GlobalKey<NavigatorState> navigatorKey;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 9, 1, 9);
    users = _FakeUserRepository();
    userService = UserService(
      repository: users,
      passwordService: passwords,
      securityAuditService: FakeSecurityAuditService(),
    );
    auth = AuthService(
      userService: userService,
      sessionService: SessionService(),
      now: () => now,
      enableSessionWatchdog: false,
    );
    navigatorKey = GlobalKey<NavigatorState>();
  });

  tearDown(() => auth.dispose());

  Future<void> signIn() async {
    await userService.addUser(_user(), password: 'password');
    expect(await auth.login(username: 'user-1', password: 'password'), isTrue);
  }

  Future<void> pumpBoundary(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: SessionActivityBoundary(
          navigatorKey: navigatorKey,
          authService: auth,
          child: Scaffold(
            body: Column(
              children: [
                TextButton(onPressed: () {}, child: const Text('Dashboard')),
                const TextField(autofocus: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pointer activity updates the active session timestamp', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    now = now.add(const Duration(minutes: 1));

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(auth.lastActivityAt, now);
  });

  testWidgets('keyboard activity updates the active session timestamp', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    now = now.add(const Duration(minutes: 1));

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();

    expect(auth.lastActivityAt, now);
  });

  testWidgets('activity at idle expiry invalidates instead of reviving', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    now = now.add(AuthService.idleTimeout);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(auth.lastActivityAt, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('resume before expiry preserves the authenticated session', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    now = now.add(const Duration(minutes: 59));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNotNull);
  });

  testWidgets('resume after idle expiry resets the navigator to Login', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    now = now.add(AuthService.idleTimeout);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('absolute expiry on resume resets the navigator to Login', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    now = now.add(AuthService.absoluteTimeout);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('session invalidation removes deep protected routes', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Deep'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Deep'), findsOneWidget);

    now = now.add(AuthService.idleTimeout);
    await auth.evaluateSessionExpiry();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(find.text('Deep'), findsNothing);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('a fresh login after lock starts fresh session timestamps', (
    tester,
  ) async {
    await signIn();
    await pumpBoundary(tester);
    now = now.add(AuthService.idleTimeout);
    await auth.evaluateSessionExpiry();
    await tester.pumpAndSettle();

    now = now.add(const Duration(minutes: 1));
    expect(await auth.login(username: 'user-1', password: 'password'), isTrue);

    expect(auth.authenticatedAt, now);
    expect(auth.lastActivityAt, now);
  });
}

User _user() => const User(
  id: 'user-1',
  username: 'user-1',
  passwordHash: '',
  role: UserRole.manager,
);

class _FakeUserRepository extends UserRepository {
  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseExecutor?) action) =>
      action(null);

  final _users = <String, UserEntity>{};

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
