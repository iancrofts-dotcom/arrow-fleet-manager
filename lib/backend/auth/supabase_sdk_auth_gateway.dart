import '../backend_client.dart';
import '../backend_profile.dart';
import 'supabase_auth_gateway.dart';

/// Production gateway. Calls are opt-in because [BackendClient] is never
/// initialized by application startup.
class SupabaseSdkAuthGateway implements SupabaseAuthGateway {
  @override
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await BackendClient.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user?.id;
  }

  @override
  Future<void> signOut() => BackendClient.client.auth.signOut();

  @override
  Future<BackendProfile?> fetchProfile(String userId) async {
    final currentUser = BackendClient.client.auth.currentUser;
    if (currentUser == null || currentUser.id != userId) {
      throw StateError('No matching authenticated backend user.');
    }
    final row = await BackendClient.client
        .from('profiles')
        .select('id, username, role, is_active, driver_legacy_id')
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : BackendProfile.fromJson(row);
  }
}
