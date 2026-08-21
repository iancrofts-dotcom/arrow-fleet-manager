import '../models/user.dart';
import '../models/user_role.dart';
import 'session_service.dart';
import 'user_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final UserService _userService = UserService.instance;
  final SessionService _sessionService = SessionService.instance;

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
    final userId = await _sessionService.getUserId();

    if (userId == null) {
      return false;
    }

    final user = await _userService.getUserById(userId);

    if (user == null || !user.isActive) {
      await _sessionService.clearSession();
      return false;
    }

    _currentUser = user;
    _requiresPasswordChange = _userService.requiresPasswordChange(user);
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    _requiresPasswordChange = false;
    await _sessionService.clearSession();
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser == null) return;

    _currentUser = await _userService.getUserById(_currentUser!.id);
    final user = _currentUser;
    _requiresPasswordChange =
        user != null && _userService.requiresPasswordChange(user);
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
