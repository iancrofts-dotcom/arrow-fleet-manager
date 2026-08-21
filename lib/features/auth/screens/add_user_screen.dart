import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../services/permission_service.dart';
import '../services/user_service.dart';
import '../widgets/user_form.dart';

class AddUserScreen extends StatelessWidget {
  const AddUserScreen({super.key});

  Future<void> _saveUser(
    BuildContext context,
    String username,
    String password,
    UserRole role,
    bool isActive,
  ) async {
    if (!await UserService.instance.isUsernameAvailable(username)) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username already exists')));

      return;
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      passwordHash: '',
      role: role,
      driverId: null,
      isActive: isActive,
    );

    try {
      await UserService.instance.addUser(user, password: password);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create user. The username may already exist.',
          ),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageUsers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to create user accounts.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add User')),
      body: UserForm(
        onSave: (username, password, role, isActive) async {
          await _saveUser(context, username, password, role, isActive);
        },
      ),
    );
  }
}
