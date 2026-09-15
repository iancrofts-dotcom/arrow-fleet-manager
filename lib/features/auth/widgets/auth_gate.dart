import 'package:flutter/material.dart';

import '../../../app/router_feature_screens_native.dart'
    if (dart.library.js_interop) '../../../app/router_feature_screens_web.dart'
    show DashboardScreen;
import '../screens/first_administrator_setup_screen.dart';
import '../screens/forced_password_change_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_initializer.dart';
import '../services/auth_service.dart';
import '../../../config/backend_mode.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authService, this.requiresSetup});

  final AuthService? authService;
  final Future<bool> Function()? requiresSetup;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<_AuthGateStateResult> _stateFuture;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService.instance;
    _stateFuture = _loadState();
  }

  Future<_AuthGateStateResult> _loadState() async {
    if (_authService.backendMode == BackendMode.local) {
      final requiresSetup =
          await (widget.requiresSetup ??
              AuthInitializer.instance.requiresFirstAdministratorSetup)();
      if (requiresSetup) {
        return const _AuthGateStateResult.requiresFirstAdministratorSetup();
      }
    }

    await _authService.restoreSession();
    if (_authService.requiresPasswordChange) {
      return const _AuthGateStateResult.requiresPasswordChange();
    }
    return const _AuthGateStateResult.normal();
  }

  void _reloadState() {
    setState(() {
      _stateFuture = _loadState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthGateStateResult>(
      future: _stateFuture,
      builder: (context, snapshot) {
        // Show loading while checking for an existing session
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final state = snapshot.data;
        if (state?.requiresFirstAdministratorSetup == true) {
          return const FirstAdministratorSetupScreen();
        }

        if (state?.requiresPasswordChange == true) {
          final user = _authService.currentUser;
          if (user != null) {
            return ForcedPasswordChangeScreen(
              user: user,
              onPasswordChanged: _reloadState,
            );
          }
        }

        // Application restarts require a fresh login, so this is normally the
        // Login screen until the user authenticates in the current process.
        if (_authService.isLoggedIn) {
          return const DashboardScreen();
        }

        return LoginScreen(authService: _authService);
      },
    );
  }
}

class _AuthGateStateResult {
  const _AuthGateStateResult._({
    this.requiresFirstAdministratorSetup = false,
    this.requiresPasswordChange = false,
  });

  const _AuthGateStateResult.normal() : this._();

  const _AuthGateStateResult.requiresFirstAdministratorSetup()
    : this._(requiresFirstAdministratorSetup: true);

  const _AuthGateStateResult.requiresPasswordChange()
    : this._(requiresPasswordChange: true);

  final bool requiresFirstAdministratorSetup;
  final bool requiresPasswordChange;
}
