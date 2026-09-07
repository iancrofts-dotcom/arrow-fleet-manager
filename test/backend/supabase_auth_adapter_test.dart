import 'package:arrow_fleet_manager/backend/auth/supabase_auth_adapter.dart';
import 'package:arrow_fleet_manager/backend/auth/supabase_auth_gateway.dart';
import 'package:arrow_fleet_manager/backend/backend_profile.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps an active backend profile', () async {
    final adapter = SupabaseAuthAdapter(_FakeGateway(profile: _profile()));

    final profile = await adapter.signIn(
      identifier: 'user@fleet.test',
      password: 'password',
    );

    expect(profile!.username, 'driver.one');
    expect(adapter.isAuthenticated, isTrue);
  });

  test(
    'missing profile rejects authentication and cleans up the remote session',
    () async {
      final gateway = _FakeGateway();
      final adapter = SupabaseAuthAdapter(gateway);

      await expectLater(
        adapter.signIn(identifier: 'user@fleet.test', password: 'password'),
        throwsStateError,
      );

      expect(gateway.signOutCalls, 1);
      expect(adapter.currentProfile, isNull);
      expect(adapter.isAuthenticated, isFalse);
    },
  );

  test(
    'inactive profile rejects authentication and cleans up the remote session',
    () async {
      final gateway = _FakeGateway(profile: _profile(isActive: false));
      final adapter = SupabaseAuthAdapter(gateway);

      await expectLater(
        adapter.signIn(identifier: 'user@fleet.test', password: 'password'),
        throwsStateError,
      );

      expect(gateway.signOutCalls, 1);
      expect(adapter.currentProfile, isNull);
      expect(adapter.isAuthenticated, isFalse);
    },
  );

  test('remote sign-in failures do not retain a prior profile', () async {
    final gateway = _FakeGateway(profile: _profile());
    final adapter = SupabaseAuthAdapter(gateway);
    await adapter.signIn(identifier: 'user@fleet.test', password: 'password');

    gateway.signInError = StateError('Remote sign-in failed.');
    await expectLater(
      adapter.signIn(identifier: 'user@fleet.test', password: 'password'),
      throwsStateError,
    );

    expect(adapter.currentProfile, isNull);
    expect(adapter.isAuthenticated, isFalse);
    expect(gateway.signOutCalls, 0);
  });

  test(
    'explicit sign-out clears local and remote authentication state',
    () async {
      final gateway = _FakeGateway(profile: _profile());
      final adapter = SupabaseAuthAdapter(gateway);
      await adapter.signIn(identifier: 'user@fleet.test', password: 'password');

      await adapter.signOut();

      expect(gateway.signOutCalls, 1);
      expect(adapter.currentProfile, isNull);
      expect(adapter.isAuthenticated, isFalse);
    },
  );

  test(
    'unknown profile roles fail closed and clean up the remote session',
    () async {
      final gateway = _FakeGateway(
        profileLoader: (_) => BackendProfile.fromJson({
          'id': 'id',
          'username': 'user',
          'role': 'unknown',
          'is_active': true,
        }),
      );
      final adapter = SupabaseAuthAdapter(gateway);

      await expectLater(
        adapter.signIn(identifier: 'user@fleet.test', password: 'password'),
        throwsStateError,
      );

      expect(gateway.signOutCalls, 1);
      expect(adapter.currentProfile, isNull);
    },
  );

  test('backend profile maps every supported role and optional driver ID', () {
    for (final entry in <String, UserRole>{
      'admin': UserRole.admin,
      'manager': UserRole.manager,
      'workshop': UserRole.workshop,
      'technician': UserRole.technician,
      'driver': UserRole.driver,
    }.entries) {
      final profile = BackendProfile.fromJson({
        'id': 'id',
        'username': 'user',
        'role': entry.key,
        'is_active': entry.key != 'driver',
        'driver_legacy_id': entry.key == 'driver' ? 42 : null,
      });

      expect(profile.role, entry.value);
      expect(profile.isActive, entry.key != 'driver');
      expect(profile.driverLegacyId, entry.key == 'driver' ? 42 : isNull);
    }
  });

  test('backend profile mapping fails closed for unknown roles', () {
    expect(
      () => BackendProfile.fromJson({
        'id': 'id',
        'username': 'user',
        'role': 'unknown',
        'is_active': true,
      }),
      throwsStateError,
    );
  });
}

BackendProfile _profile({bool isActive = true}) => BackendProfile(
  id: 'id',
  username: 'driver.one',
  role: UserRole.driver,
  isActive: isActive,
);

class _FakeGateway implements SupabaseAuthGateway {
  _FakeGateway({this.profile, this.profileLoader});

  BackendProfile? profile;
  BackendProfile? Function(String userId)? profileLoader;
  Object? signInError;
  int signOutCalls = 0;

  @override
  Future<BackendProfile?> fetchProfile(String userId) async {
    final loader = profileLoader;
    if (loader != null) {
      return loader(userId);
    }
    return profile;
  }

  @override
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (signInError case final error?) {
      throw error;
    }
    return 'id';
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}
