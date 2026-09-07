import '../backend_profile.dart';
import 'fleet_auth_adapter.dart';
import 'supabase_auth_gateway.dart';

class SupabaseAuthAdapter implements FleetAuthAdapter {
  SupabaseAuthAdapter(this._gateway);
  final SupabaseAuthGateway _gateway;
  BackendProfile? _profile;
  @override bool get isAuthenticated => _profile != null;
  @override BackendProfile? get currentProfile => _profile;
  @override
  Future<BackendProfile?> signIn({
    required String identifier,
    required String password,
  }) async {
    _profile = null;
    final userId = await _gateway.signInWithEmail(email: identifier, password: password);
    if (userId == null) {
      return null;
    }

    try {
      final profile = await _gateway.fetchProfile(userId);
      if (profile == null) {
        throw StateError('FleetIQ profile is missing.');
      }
      if (!profile.isActive) {
        throw StateError('FleetIQ account is inactive.');
      }
      return _profile = profile;
    } catch (_) {
      await _gateway.signOut();
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _gateway.signOut();
    _profile = null;
  }
}
