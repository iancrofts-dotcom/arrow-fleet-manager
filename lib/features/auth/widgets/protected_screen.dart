import 'package:flutter/material.dart';

import '../screens/forced_password_change_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';

class ProtectedScreen extends StatefulWidget {
  final bool Function(PermissionService permissions) allow;
  final Widget child;

  const ProtectedScreen({super.key, required this.allow, required this.child});

  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends State<ProtectedScreen> {
  late Future<SessionValidationResult> _validationFuture;

  @override
  void initState() {
    super.initState();
    _validationFuture = AuthService.instance.revalidateCurrentSession();
  }

  void _retry() {
    setState(() {
      _validationFuture = AuthService.instance.revalidateCurrentSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionValidationResult>(
      future: _validationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == SessionValidationResult.refreshFailed) {
          return Scaffold(
            appBar: AppBar(title: const Text('Unable to verify access')),
            body: Center(
              child: FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          );
        }

        if (snapshot.data != SessionValidationResult.authenticated) {
          return const LoginScreen();
        }

        if (AuthService.instance.requiresPasswordChange) {
          final user = AuthService.instance.currentUser;
          if (user != null) {
            return ForcedPasswordChangeScreen(user: user);
          }
          return const LoginScreen();
        }

        final permissions = PermissionService.instance;

        if (widget.allow(permissions)) {
          return widget.child;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Access Denied')),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 72),
                SizedBox(height: 16),
                Text(
                  'You do not have permission to access this page.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
