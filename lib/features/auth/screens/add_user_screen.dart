import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
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
    final existing =
        await UserService.instance.getUserByUsername(username);

    if (existing != null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username already exists'),
        ),
      );

      return;
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      passwordHash: password,
      role: role,
      driverId: null,
      isActive: isActive,
    );

    await UserService.instance.saveUser(user);

    if (!context.mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
      ),
      body: UserForm(
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