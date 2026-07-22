import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
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
      passwordHash:
          password.isEmpty ? user.passwordHash : password,
      role: role,
      driverId: user.driverId,
      isActive: isActive,
    );

    await UserService.instance.updateUser(updatedUser);

    if (!context.mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
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