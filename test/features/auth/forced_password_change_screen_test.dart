import 'package:arrow_fleet_manager/features/auth/models/user.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_entity.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/repositories/user_repository.dart';
import 'package:arrow_fleet_manager/features/auth/screens/forced_password_change_screen.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/password_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/session_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const passwords = PasswordService(workFactor: 4);

  late _FakeUserRepository users;
  late UserService userService;
  late AuthService authService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    users = _FakeUserRepository();
    userService = UserService(repository: users, passwordService: passwords);
    authService = AuthService(
      userService: userService,
      sessionService: SessionService(),
    );
  });

  Future<void> enterReplacementPassword(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'new-password');
    await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'successful forced password replacement clears the session and notifies AuthGate',
    (tester) async {
      const seeded = User(
        id: 'admin-id',
        username: 'admin',
        passwordHash: '',
        role: UserRole.admin,
        driverId: 7,
        isActive: true,
      );
      users.seed(seeded.copyWith(passwordHash: passwords.hash('admin')));
      expect(
        await authService.login(username: 'admin', password: 'admin'),
        isTrue,
      );
      expect(authService.requiresPasswordChange, isTrue);

      var notified = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ForcedPasswordChangeScreen(
            user: authService.currentUser!,
            authService: authService,
            onPasswordChanged: () => notified = true,
          ),
        ),
      );

      await enterReplacementPassword(tester);

      final updated = await userService.getUserById(seeded.id);
      expect(notified, isTrue);
      expect(updated, isNotNull);
      expect(updated!.id, seeded.id);
      expect(updated.role, seeded.role);
      expect(updated.driverId, seeded.driverId);
      expect(updated.isActive, isTrue);
      expect(passwords.isSecureHash(updated.passwordHash), isTrue);
      expect(userService.requiresPasswordChange(updated), isFalse);
      expect(authService.currentUser, isNull);
      expect(await SessionService().getUserId(), isNull);
      final restartedAuth = AuthService(
        userService: userService,
        sessionService: SessionService(),
      );
      expect(await restartedAuth.restoreSession(), isFalse);
      expect(restartedAuth.requiresPasswordChange, isFalse);
      expect(
        await userService.login(username: 'admin', password: 'admin'),
        isNull,
      );
      expect(
        await userService.login(username: 'admin', password: 'new-password'),
        isNotNull,
      );
    },
  );

  testWidgets('a failed replacement keeps the screen available for retry', (
    tester,
  ) async {
    const seeded = User(
      id: 'manager-id',
      username: 'manager',
      passwordHash: '',
      role: UserRole.manager,
    );
    users.seed(seeded.copyWith(passwordHash: passwords.hash('manager')));
    expect(
      await authService.login(username: 'manager', password: 'manager'),
      isTrue,
    );
    users.failUpdates = true;

    await tester.pumpWidget(
      MaterialApp(
        home: ForcedPasswordChangeScreen(
          user: authService.currentUser!,
          authService: authService,
        ),
      ),
    );

    await enterReplacementPassword(tester);

    expect(find.byType(ForcedPasswordChangeScreen), findsOneWidget);
    expect(find.text('Could not change password. Try again.'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(authService.currentUser, isNotNull);
    expect(authService.requiresPasswordChange, isTrue);
  });

  test(
    'historic manager replacement clears the forced-change requirement',
    () async {
      const seeded = User(
        id: 'manager-id',
        username: 'manager',
        passwordHash: '',
        role: UserRole.manager,
      );
      users.seed(seeded.copyWith(passwordHash: passwords.hash('manager')));
      expect(
        await authService.login(username: 'manager', password: 'manager'),
        isTrue,
      );
      expect(authService.requiresPasswordChange, isTrue);

      await authService.completeForcedPasswordChange(
        authService.currentUser!,
        newPassword: 'manager-new-password',
      );

      final updated = await userService.getUserById(seeded.id);
      expect(updated, isNotNull);
      expect(userService.requiresPasswordChange(updated!), isFalse);
      expect(
        await userService.login(username: 'manager', password: 'manager'),
        isNull,
      );
      expect(
        await userService.login(
          username: 'manager',
          password: 'manager-new-password',
        ),
        isNotNull,
      );
    },
  );
}

class _FakeUserRepository extends UserRepository {
  final _users = <String, UserEntity>{};
  bool failUpdates = false;

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
  Future<void> insertUser(UserEntity user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    if (failUpdates) throw StateError('Update failed');
    _users[user.id] = user;
  }
}
