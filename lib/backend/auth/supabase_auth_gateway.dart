import '../backend_profile.dart';

abstract interface class SupabaseAuthGateway {
  Future<String?> signInWithEmail({required String email, required String password});
  Future<void> signOut();
  Future<BackendProfile?> fetchProfile(String userId);
}
