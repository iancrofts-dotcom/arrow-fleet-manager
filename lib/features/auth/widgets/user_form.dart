import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';

class UserForm extends StatefulWidget {
  const UserForm({
    super.key,
    this.user,
    required this.onSave,
  });

  final User? user;
  final Future<void> Function(
    String username,
    String password,
    UserRole role,
    bool isActive,
  ) onSave;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

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

    _role = widget.user?.role ?? UserRole.driver;

    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await widget.onSave(
      _usernameController.text.trim(),
      _passwordController.text,
      _role,
      _isActive,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });
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
            decoration: const InputDecoration(
              labelText: 'Username',
            ),
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
              labelText: _isEdit
                  ? 'New Password (optional)'
                  : 'Password',
            ),
            validator: (value) {
              if (!_isEdit &&
                  (value == null || value.length < 4)) {
                return 'Password must be at least 4 characters';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            decoration: const InputDecoration(
              labelText: 'Role',
            ),
            items: UserRole.values.map((role) {
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