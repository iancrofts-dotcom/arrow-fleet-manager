import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../services/permission_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/user_form.dart';

class EditUserScreen extends StatelessWidget {
  const EditUserScreen({super.key, required this.user});

  final User user;

  Future<void> _saveUser(
    BuildContext context,
    String username,
    String password,
    UserRole role,
    bool isActive,
  ) async {
    if (username != user.username &&
        !await UserService.instance.isUsernameAvailable(
          username,
          excludingUserId: user.id,
        )) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username already exists')));
      return;
    }

    final updatedUser = User(
      id: user.id,
      username: username,
      passwordHash: user.passwordHash,
      role: role,
      driverId: user.driverId,
      isActive: isActive,
    );

    try {
      await UserService.instance.updateManagedUser(
        updatedUser,
        actingUserId: AuthService.instance.requireLogin().id,
        newPassword: password.isEmpty ? null : password,
      );
    } on UserManagementException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save user. The username may already exist.'),
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
          child: Text('You do not have permission to edit user accounts.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: UserForm(
        user: user,
        onSave: (username, password, role, isActive) async {
          await _saveUser(context, username, password, role, isActive);
        },
      ),
    );
  }
}
