import 'package:arrow_fleet_manager/backend/auth/fleet_auth_adapter.dart';
import 'package:arrow_fleet_manager/backend/backend_profile.dart';
import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/screens/login_screen.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  test('local mode remains the default and keeps username semantics', () {
    final auth = AuthService(enableSessionWatchdog: false);

    expect(auth.backendMode, BackendMode.local);
    expect(auth.usesEmailLogin, isFalse);
  });

  for (final entry in <UserRole, bool>{
    UserRole.admin: true,
    UserRole.manager: true,
    UserRole.workshop: false,
    UserRole.driver: false,
  }.entries) {
    test('Supabase ${entry.key.name} drives application permissions', () async {
      final adapter = _FakeRemoteAuthAdapter(_profile(entry.key));
      final auth = AuthService(enableSessionWatchdog: false)
        ..configureBackend(
          mode: BackendMode.supabase,
          remoteAuthAdapter: adapter,
        );

      expect(auth.usesEmailLogin, isTrue);
      expect(
        await auth.login(username: 'user@fleet.test', password: 'remote-only'),
        isTrue,
      );
      expect(auth.currentRole, entry.key);
      final permissions = PermissionService(authService: auth);
      expect(
        permissions.canManageVehicles,
        entry.value,
      );
      expect(permissions.canViewVehicles, entry.key != UserRole.driver);
    });
  }

  test(
    'remote rejection does not create a local authentication state',
    () async {
      final adapter = _FakeRemoteAuthAdapter(null);
      final auth = AuthService(enableSessionWatchdog: false)
        ..configureBackend(
          mode: BackendMode.supabase,
          remoteAuthAdapter: adapter,
        );

      expect(
        await auth.login(username: 'user@fleet.test', password: 'rejected'),
        isFalse,
      );
      expect(auth.isLoggedIn, isFalse);
    },
  );

  test('remote logout uses the selected adapter', () async {
    final adapter = _FakeRemoteAuthAdapter(_profile(UserRole.admin));
    final auth = AuthService(
      enableSessionWatchdog: false,
    )..configureBackend(mode: BackendMode.supabase, remoteAuthAdapter: adapter);
    await auth.login(username: 'user@fleet.test', password: 'remote-only');

    await auth.logout();

    expect(adapter.signOutCalls, 1);
    expect(auth.isLoggedIn, isFalse);
  });

  test('Supabase mode requires a remote adapter', () {
    final auth = AuthService(enableSessionWatchdog: false);

    expect(
      () => auth.configureBackend(mode: BackendMode.supabase),
      throwsArgumentError,
    );
  });

  testWidgets('login field follows local username semantics', (tester) async {
    final auth = AuthService(enableSessionWatchdog: false);

    await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: auth)));

    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsNothing);
  });

  testWidgets('login field follows Supabase email semantics', (tester) async {
    final auth = AuthService(enableSessionWatchdog: false)
      ..configureBackend(
        mode: BackendMode.supabase,
        remoteAuthAdapter: _FakeRemoteAuthAdapter(null),
      );

    await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: auth)));

    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Username'), findsNothing);
  });
}

BackendProfile _profile(UserRole role) => BackendProfile(
  id: 'profile-id',
  username: 'remote.user',
  role: role,
  isActive: true,
);

class _FakeRemoteAuthAdapter implements FleetAuthAdapter {
  _FakeRemoteAuthAdapter(this.profile);

  final BackendProfile? profile;
  int signOutCalls = 0;
  BackendProfile? _currentProfile;

  @override
  BackendProfile? get currentProfile => _currentProfile;

  @override
  bool get isAuthenticated => _currentProfile != null;

  @override
  Future<BackendProfile?> signIn({
    required String identifier,
    required String password,
  }) async => _currentProfile = profile;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _currentProfile = null;
  }
}
