import 'package:flutter/material.dart';

import '../../dashboard/dashboard_screen.dart';
import '../screens/first_administrator_setup_screen.dart';
import '../screens/forced_password_change_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_initializer.dart';
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<_AuthGateStateResult> _stateFuture;

  @override
  void initState() {
    super.initState();
    _stateFuture = _loadState();
  }

  Future<_AuthGateStateResult> _loadState() async {
    final requiresSetup = await AuthInitializer.instance
        .requiresFirstAdministratorSetup();
    if (requiresSetup) {
      return const _AuthGateStateResult.requiresFirstAdministratorSetup();
    }

    await AuthService.instance.restoreSession();
    if (AuthService.instance.requiresPasswordChange) {
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
          final user = AuthService.instance.currentUser;
          if (user != null) {
            return ForcedPasswordChangeScreen(
              user: user,
              onPasswordChanged: _reloadState,
            );
          }
        }

        // Application restarts require a fresh login, so this is normally the
        // Login screen until the user authenticates in the current process.
        if (AuthService.instance.isLoggedIn) {
          return const DashboardScreen();
        }

        return const LoginScreen();
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
