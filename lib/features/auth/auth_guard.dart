import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/dashboard/dashboard_screen.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  late final Future<bool> _startup;

  @override
  void initState() {
    super.initState();
    _startup = AuthService.instance.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final loggedIn = snapshot.data ?? false;

        if (loggedIn) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}