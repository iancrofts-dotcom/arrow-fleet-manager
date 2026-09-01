import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';

/// Observes app-wide physical activity and session invalidation without
/// changing individual feature screens.
class SessionActivityBoundary extends StatefulWidget {
  const SessionActivityBoundary({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.authService,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final AuthService? authService;

  @override
  State<SessionActivityBoundary> createState() =>
      _SessionActivityBoundaryState();
}

class _SessionActivityBoundaryState extends State<SessionActivityBoundary>
    with WidgetsBindingObserver {
  static const _pointerMoveThrottle = Duration(seconds: 1);

  late final AuthService _authService;
  late bool _wasAuthenticated;
  DateTime? _lastPointerMoveAt;
  bool _loginResetInProgress = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService.instance;
    _wasAuthenticated = _authService.isLoggedIn;
    _authService.addListener(_onAuthStateChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_authService.evaluateSessionExpiry());
    }
  }

  void _onAuthStateChanged() {
    final isAuthenticated = _authService.isLoggedIn;
    final wasInvalidated = _wasAuthenticated && !isAuthenticated;
    _wasAuthenticated = isAuthenticated;

    if (wasInvalidated) {
      _resetToLogin();
    }
  }

  void _resetToLogin() {
    if (_loginResetInProgress) {
      return;
    }

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _loginResetInProgress = true;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loginResetInProgress = false;
      }
    });
  }

  void _registerActivity() {
    unawaited(_authService.registerActivity());
  }

  void _registerPointerMoveActivity() {
    final now = DateTime.now();
    final lastPointerMoveAt = _lastPointerMoveAt;
    if (lastPointerMoveAt != null &&
        now.difference(lastPointerMoveAt) < _pointerMoveThrottle) {
      return;
    }

    _lastPointerMoveAt = now;
    _registerActivity();
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _registerActivity();
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _onKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _registerActivity(),
        onPointerMove: (_) => _registerPointerMoveActivity(),
        onPointerSignal: (_) => _registerActivity(),
        child: widget.child,
      ),
    );
  }
}
