import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

class ForcedPasswordChangeScreen extends StatefulWidget {
  const ForcedPasswordChangeScreen({super.key, required this.user});

  final User user;

  @override
  State<ForcedPasswordChangeScreen> createState() =>
      _ForcedPasswordChangeScreenState();
}

class _ForcedPasswordChangeScreenState
    extends State<ForcedPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final password = _passwordController.text;
    if ((widget.user.username == 'admin' && password == 'admin') ||
        (widget.user.username == 'manager' && password == 'manager')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a new password.')));
      return;
    }

    setState(() {
      _saving = true;
    });
    try {
      await UserService.instance.updateUser(widget.user, newPassword: password);
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not change password. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.lock_reset,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Change your password',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This account uses a historical default password. '
                          'Choose a new password before continuing.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New password',
                          ),
                          validator: (value) =>
                              value == null || value.length < 4
                              ? 'Password must be at least 4 characters'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmationController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm new password',
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: const Icon(Icons.save),
                          label: Text(
                            _saving ? 'Saving...' : 'Change password',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
