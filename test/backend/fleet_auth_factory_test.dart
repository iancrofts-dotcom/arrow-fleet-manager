import 'package:arrow_fleet_manager/backend/auth/fleet_auth_factory.dart';
import 'package:arrow_fleet_manager/backend/auth/local_auth_adapter.dart';
import 'package:arrow_fleet_manager/backend/auth/supabase_auth_adapter.dart';
import 'package:arrow_fleet_manager/backend/auth/supabase_auth_gateway.dart';
import 'package:arrow_fleet_manager/backend/backend_profile.dart';
import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to the local authentication adapter', () {
    expect(createFleetAuthAdapter(), isA<LocalAuthAdapter>());
  });

  test('selects the local authentication adapter explicitly', () {
    expect(
      createFleetAuthAdapter(mode: BackendMode.local),
      isA<LocalAuthAdapter>(),
    );
  });

  test('selects the Supabase authentication adapter with a gateway', () {
    expect(
      createFleetAuthAdapter(
        mode: BackendMode.supabase,
        supabaseGateway: _FakeGateway(),
      ),
      isA<SupabaseAuthAdapter>(),
    );
  });

  test('requires an explicit gateway for Supabase authentication', () {
    expect(
      () => createFleetAuthAdapter(mode: BackendMode.supabase),
      throwsArgumentError,
    );
  });
}

class _FakeGateway implements SupabaseAuthGateway {
  @override
  Future<BackendProfile?> fetchProfile(String userId) async => null;

  @override
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {}
}
