import '../../features/auth/services/auth_service.dart';
import '../backend_profile.dart';
import 'fleet_auth_adapter.dart';

/// Local adapter: [identifier] is the existing FleetIQ username.
class LocalAuthAdapter implements FleetAuthAdapter {
  LocalAuthAdapter(this._authService);
  final AuthService _authService;

  @override bool get isAuthenticated => _authService.isLoggedIn;
  @override BackendProfile? get currentProfile {
    final user = _authService.currentUser;
    if (user == null) return null;
    return BackendProfile(id: user.id, username: user.username, role: user.role, isActive: user.isActive, driverLegacyId: user.driverId);
  }
  @override
  Future<BackendProfile?> signIn({required String identifier, required String password}) async {
    if (!await _authService.login(username: identifier, password: password)) return null;
    return currentProfile;
  }
  @override Future<void> signOut() => _authService.logout();
}
