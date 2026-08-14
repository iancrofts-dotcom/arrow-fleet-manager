import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/user_service.dart';

/// Self-service account details for the currently signed-in Driver.
///
/// This screen deliberately reloads the account using the authenticated user
/// ID before displaying or saving it, so it cannot be used to edit another
/// user's account through direct navigation.
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  User? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentDriver();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentDriver() async {
    final currentUser = AuthService.instance.currentUser;
    if (!PermissionService.instance.canViewOwnAccount ||
        currentUser == null ||
        currentUser.role != UserRole.driver) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'You do not have permission to access this account.';
      });
      return;
    }

    final user = await UserService.instance.getUserById(currentUser.id);

    if (!mounted) return;

    if (user == null || user.id != currentUser.id || user.role != UserRole.driver) {
      setState(() {
        _loading = false;
        _error = 'Your Driver account could not be verified.';
      });
      return;
    }

    setState(() {
      _user = user;
      _usernameController.text = user.username;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final user = _user;
    final currentUser = AuthService.instance.currentUser;

    if (!_formKey.currentState!.validate() ||
        user == null ||
        currentUser == null ||
        user.id != currentUser.id ||
        currentUser.role != UserRole.driver) {
      return;
    }

    final username = _usernameController.text.trim();
    if (username != user.username) {
      final existing = await UserService.instance.getUserByUsername(username);
      if (existing != null && existing.id != user.id) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already exists.')),
        );
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    final latestUser = await UserService.instance.getUserById(currentUser.id);
    if (latestUser == null ||
        latestUser.id != currentUser.id ||
        latestUser.role != UserRole.driver) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Your Driver account could not be verified.';
      });
      return;
    }

    await UserService.instance.updateUser(
      latestUser.copyWith(
        username: username,
        passwordHash: _passwordController.text.isEmpty
            ? latestUser.passwordHash
            : _passwordController.text,
      ),
    );
    await AuthService.instance.refreshCurrentUser();

    if (!mounted) return;

    setState(() {
      _user = AuthService.instance.currentUser;
      _passwordController.clear();
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your account has been updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error ?? 'Unable to load your account.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a username.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (optional)',
              ),
              validator: (value) => value != null &&
                      value.isNotEmpty &&
                      value.length < 4
                  ? 'Password must be at least 4 characters.'
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Role: ${_user!.role.displayName}'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
