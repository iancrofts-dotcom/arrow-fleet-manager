import '../models/user.dart';
import '../models/user_role.dart';
import 'session_service.dart';
import 'user_service.dart';

class AuthService {
  AuthService({UserService? userService, SessionService? sessionService})
    : _userService = userService ?? UserService.instance,
      _sessionService = sessionService ?? SessionService.instance;

  static final AuthService instance = AuthService();

  final UserService _userService;
  final SessionService _sessionService;

  User? _currentUser;
  bool _requiresPasswordChange = false;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  bool get requiresPasswordChange => _requiresPasswordChange;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final user = await _userService.login(
      username: username,
      password: password,
    );

    if (user == null) {
      return false;
    }

    _currentUser = user;
    _requiresPasswordChange = _userService.requiresPasswordChange(user);

    // Save session
    await _sessionService.saveUserId(user.id);

    return true;
  }

  Future<bool> restoreSession() async {
    return (await revalidateCurrentSession()) ==
        SessionValidationResult.authenticated;
  }

  Future<void> logout() async {
    _currentUser = null;
    _requiresPasswordChange = false;
    await _sessionService.clearSession();
  }

  /// Replaces a historic bootstrap credential, confirms the persisted user no
  /// longer requires replacement, then ends the current session. Keeping this
  /// sequence here prevents the UI from reporting success against stale or
  /// unverified account state.
  Future<void> completeForcedPasswordChange(
    User user, {
    required String newPassword,
  }) async {
    await _userService.updateUser(user, newPassword: newPassword);

    final persistedUser = await _userService.getUserById(user.id);
    if (persistedUser == null ||
        _userService.requiresPasswordChange(persistedUser)) {
      throw StateError('Could not verify the updated password.');
    }

    await logout();
  }

  /// Reloads the session user from persisted storage at an authorization
  /// boundary. Missing and inactive accounts are invalidated; repository
  /// failures intentionally retain the session but return [refreshFailed] so
  /// callers can fail closed without treating a transient database issue as a
  /// logout.
  Future<SessionValidationResult> revalidateCurrentSession() async {
    final userId = _currentUser?.id ?? await _sessionService.getUserId();
    if (userId == null) {
      return SessionValidationResult.unauthenticated;
    }

    try {
      final user = await _userService.getUserById(userId);
      if (user == null || !user.isActive) {
        _currentUser = null;
        _requiresPasswordChange = false;
        await _sessionService.clearSession();
        return SessionValidationResult.unauthenticated;
      }

      _currentUser = user;
      _requiresPasswordChange = _userService.requiresPasswordChange(user);
      return SessionValidationResult.authenticated;
    } catch (_) {
      return SessionValidationResult.refreshFailed;
    }
  }

  Future<void> refreshCurrentUser() async {
    await revalidateCurrentSession();
  }

  bool hasRole(UserRole role) {
    return _currentUser?.role == role;
  }

  bool get isAdmin => hasRole(UserRole.admin);

  bool get isDriver => hasRole(UserRole.driver);

  UserRole? get currentRole => _currentUser?.role;

  String? get currentUserId => _currentUser?.id;

  int? get currentDriverId => _currentUser?.driverId;

  User requireLogin() {
    final user = _currentUser;

    if (user == null) {
      throw StateError('No user is currently logged in.');
    }

    return user;
  }
}

enum SessionValidationResult { authenticated, unauthenticated, refreshFailed }
