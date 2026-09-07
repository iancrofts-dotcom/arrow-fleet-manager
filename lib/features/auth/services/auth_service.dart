import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../backend/auth/fleet_auth_adapter.dart';
import '../../../config/backend_mode.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'session_service.dart';
import 'user_service.dart';

typedef NowProvider = DateTime Function();

class AuthService extends ChangeNotifier {
  AuthService({
    UserService? userService,
    SessionService? sessionService,
    NowProvider? now,
    this.enableSessionWatchdog = true,
  }) : _userService = userService ?? UserService.instance,
       _sessionService = sessionService ?? SessionService.instance,
       _now = now ?? DateTime.now;

  static const idleTimeout = Duration(minutes: 60);
  static const absoluteTimeout = Duration(hours: 12);
  static const _watchdogInterval = Duration(minutes: 1);

  static final AuthService instance = AuthService();

  final UserService _userService;
  final SessionService _sessionService;
  final NowProvider _now;
  final bool enableSessionWatchdog;

  BackendMode _backendMode = BackendMode.local;
  FleetAuthAdapter? _remoteAuthAdapter;

  User? _currentUser;
  bool _requiresPasswordChange = false;
  DateTime? _authenticatedAt;
  DateTime? _lastActivityAt;
  Timer? _sessionWatchdog;

  User? get currentUser => _currentUser;

  BackendMode get backendMode => _backendMode;

  bool get usesEmailLogin => _backendMode == BackendMode.supabase;

  bool get isLoggedIn => _currentUser != null;

  bool get requiresPasswordChange => _requiresPasswordChange;

  DateTime? get authenticatedAt => _authenticatedAt;

  DateTime? get lastActivityAt => _lastActivityAt;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final User? user;
    if (_backendMode == BackendMode.local) {
      user = await _userService.login(username: username, password: password);
    } else {
      final profile = await _remoteAuthAdapter!.signIn(
        identifier: username,
        password: password,
      );
      user = profile == null
          ? null
          : User(
              id: profile.id,
              username: profile.username,
              passwordHash: '',
              role: profile.role,
              driverId: profile.driverLegacyId,
              isActive: profile.isActive,
            );
    }

    if (user == null) {
      return false;
    }

    final loginTime = _now();
    _currentUser = user;
    _requiresPasswordChange =
        _backendMode == BackendMode.local &&
        _userService.requiresPasswordChange(user);
    _authenticatedAt = loginTime;
    _lastActivityAt = loginTime;

    // Kept only as compatibility cleanup for existing installations. It is
    // never used to restore authentication after an application restart.
    if (_backendMode == BackendMode.local) {
      await _sessionService.saveUserId(user.id);
    }
    _startSessionWatchdog();
    notifyListeners();

    return true;
  }

  /// Application restarts require a fresh login. Older versions persisted a
  /// user ID, so remove it rather than treating it as authentication state.
  Future<bool> restoreSession() async {
    await _invalidateSession(notify: false);
    return false;
  }

  Future<void> logout() => _invalidateSession();

  void configureBackend({
    required BackendMode mode,
    FleetAuthAdapter? remoteAuthAdapter,
  }) {
    if (mode == BackendMode.supabase && remoteAuthAdapter == null) {
      throw ArgumentError('Supabase mode requires a remote auth adapter.');
    }
    _backendMode = mode;
    _remoteAuthAdapter = remoteAuthAdapter;
  }

  /// Records user activity for the in-memory session. Activity never extends
  /// the absolute lifetime and cannot revive an expired session.
  Future<void> registerActivity() async {
    if (_currentUser == null ||
        _authenticatedAt == null ||
        _lastActivityAt == null) {
      return;
    }

    if (await evaluateSessionExpiry() == SessionExpiryStatus.expired) {
      return;
    }

    _lastActivityAt = _now();
  }

  /// Evaluates the in-memory session lifetime without relying on watchdog tick
  /// counts. Normal expiry is represented by [SessionExpiryStatus.expired].
  Future<SessionExpiryStatus> evaluateSessionExpiry() async {
    final authenticatedAt = _authenticatedAt;
    final lastActivityAt = _lastActivityAt;

    if (_currentUser == null) {
      return SessionExpiryStatus.noSession;
    }

    if (authenticatedAt == null || lastActivityAt == null) {
      await _invalidateSession();
      return SessionExpiryStatus.expired;
    }

    final now = _now();
    final isIdleExpired = now.difference(lastActivityAt) >= idleTimeout;
    final isAbsoluteExpired =
        now.difference(authenticatedAt) >= absoluteTimeout;

    if (!isIdleExpired && !isAbsoluteExpired) {
      return SessionExpiryStatus.valid;
    }

    await _invalidateSession();
    return SessionExpiryStatus.expired;
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
    if (_currentUser == null) {
      await _invalidateSession(notify: false);
      return SessionValidationResult.unauthenticated;
    }

    if (await evaluateSessionExpiry() != SessionExpiryStatus.valid) {
      return SessionValidationResult.unauthenticated;
    }

    if (_backendMode == BackendMode.supabase) {
      return _remoteAuthAdapter?.isAuthenticated == true
          ? SessionValidationResult.authenticated
          : SessionValidationResult.unauthenticated;
    }

    final userId = _currentUser?.id;
    if (userId == null) {
      return SessionValidationResult.unauthenticated;
    }

    try {
      final user = await _userService.getUserById(userId);
      if (user == null || !user.isActive) {
        await _invalidateSession();
        return SessionValidationResult.unauthenticated;
      }

      _currentUser = user;
      _requiresPasswordChange = _userService.requiresPasswordChange(user);
      notifyListeners();
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

  void _startSessionWatchdog() {
    if (!enableSessionWatchdog || _sessionWatchdog != null) {
      return;
    }

    _sessionWatchdog = Timer.periodic(_watchdogInterval, (_) {
      unawaited(evaluateSessionExpiry());
    });
  }

  Future<void> _invalidateSession({bool notify = true}) async {
    final hadAuthState =
        _currentUser != null ||
        _requiresPasswordChange ||
        _authenticatedAt != null ||
        _lastActivityAt != null;

    _sessionWatchdog?.cancel();
    _sessionWatchdog = null;
    _currentUser = null;
    _requiresPasswordChange = false;
    _authenticatedAt = null;
    _lastActivityAt = null;
    if (_backendMode == BackendMode.supabase) {
      try {
        await _remoteAuthAdapter?.signOut();
      } catch (_) {
        // Local state remains invalidated; never expose remote auth details.
      }
    } else {
      await _sessionService.clearSession();
    }

    if (notify && hadAuthState) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sessionWatchdog?.cancel();
    super.dispose();
  }
}

enum SessionExpiryStatus { noSession, valid, expired }

enum SessionValidationResult { authenticated, unauthenticated, refreshFailed }
