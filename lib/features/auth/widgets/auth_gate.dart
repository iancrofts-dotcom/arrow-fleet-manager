import 'package:flutter/material.dart';

import '../../dashboard/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthService.instance.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        // Show loading while checking for an existing session
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If restoreSession() found a valid session,
        // AuthService.isLoggedIn will now be true.
        if (AuthService.instance.isLoggedIn) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}