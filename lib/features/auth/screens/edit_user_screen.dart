import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../services/permission_service.dart';
import '../services/user_service.dart';
import '../widgets/user_form.dart';

class EditUserScreen extends StatelessWidget {
  const EditUserScreen({
    super.key,
    required this.user,
  });

  final User user;

  Future<void> _saveUser(
    BuildContext context,
    String username,
    String password,
    UserRole role,
    bool isActive,
  ) async {
    final updatedUser = User(
      id: user.id,
      username: username,
      passwordHash: user.passwordHash,
      role: role,
      driverId: user.driverId,
      isActive: isActive,
    );

    await UserService.instance.updateUser(
      updatedUser,
      newPassword: password.isEmpty ? null : password,
    );

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
      appBar: AppBar(
        title: const Text('Edit User'),
      ),
      body: UserForm(
        user: user,
        onSave: (
          username,
          password,
          role,
          isActive,
        ) async {
          await _saveUser(
            context,
            username,
            password,
            role,
            isActive,
          );
        },
      ),
    );
  }
}
