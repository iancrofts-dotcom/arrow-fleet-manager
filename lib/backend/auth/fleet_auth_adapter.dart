import '../backend_profile.dart';

abstract interface class FleetAuthAdapter {
  bool get isAuthenticated;
  BackendProfile? get currentProfile;
  Future<BackendProfile?> signIn({
    required String identifier,
    required String password,
  });
  Future<void> signOut();
}
