import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../services/password_policy.dart';

class UserForm extends StatefulWidget {
  const UserForm({super.key, this.user, required this.onSave});

  final User? user;
  final Future<void> Function(
    String username,
    String password,
    UserRole role,
    bool isActive,
  )
  onSave;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  static const _genericRoles = <UserRole>[
    UserRole.technician,
    UserRole.manager,
    UserRole.workshop,
    UserRole.admin,
  ];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmationController;

  late UserRole _role;
  late bool _isActive;

  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(
      text: widget.user?.username ?? '',
    );

    _passwordController = TextEditingController();
    _confirmationController = TextEditingController();

    _role = widget.user?.role ?? UserRole.technician;

    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(
        _usernameController.text.trim(),
        _passwordController.text,
        _role,
        _isActive,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save the user. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  List<UserRole> get _availableRoles {
    final user = widget.user;
    if (user?.role == UserRole.driver && _role == UserRole.driver) {
      return [UserRole.driver, ..._genericRoles];
    }

    return _genericRoles;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a username';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _isEdit ? 'New Password (optional)' : 'Password',
            ),
            validator: (value) {
              final password = value ?? '';
              if (!_isEdit || password.isNotEmpty) {
                return PasswordPolicy.validate(password);
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmationController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: _isEdit ? 'Confirm New Password' : 'Confirm Password',
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: _availableRoles.map((role) {
              return DropdownMenuItem<UserRole>(
                value: role,
                child: Text(role.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _role = value;
              });
            },
          ),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),

          const SizedBox(height: 30),

          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save),
            label: Text(
              _saving
                  ? 'Saving...'
                  : _isEdit
                  ? 'Save Changes'
                  : 'Create User',
            ),
          ),
        ],
      ),
    );
  }
}
