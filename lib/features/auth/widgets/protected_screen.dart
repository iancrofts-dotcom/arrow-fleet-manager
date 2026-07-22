import 'package:flutter/material.dart';

import '../services/permission_service.dart';

class ProtectedScreen extends StatelessWidget {
  final bool Function(PermissionService permissions) allow;
  final Widget child;

  const ProtectedScreen({
    super.key,
    required this.allow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;

    if (allow(permissions)) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 72,
            ),
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
  }
}