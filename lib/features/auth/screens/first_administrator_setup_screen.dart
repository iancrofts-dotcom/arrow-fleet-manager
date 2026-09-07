import 'package:flutter/material.dart';
import '../../../shared/widgets/fleetiq_brand.dart';

import '../models/user.dart';
import '../models/user_role.dart';
import '../services/auth_initializer.dart';
import '../services/password_policy.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

class FirstAdministratorSetupScreen extends StatefulWidget {
  const FirstAdministratorSetupScreen({super.key});

  @override
  State<FirstAdministratorSetupScreen> createState() =>
      _FirstAdministratorSetupScreenState();
}

class _FirstAdministratorSetupScreenState
    extends State<FirstAdministratorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _checking = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checkSetupAvailability();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _checkSetupAvailability() async {
    final requiresSetup = await AuthInitializer.instance
        .requiresFirstAdministratorSetup();
    if (!mounted) return;

    if (!requiresSetup) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    setState(() {
      _checking = false;
    });
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final created = await UserService.instance.createFirstAdministrator(
        User(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          username: _usernameController.text.trim(),
          passwordHash: '',
          // The service enforces Administrator and active state.
          role: UserRole.admin,
        ),
        password: _passwordController.text,
      );
      if (!mounted) return;

      if (!created) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An Administrator already exists. Please sign in.'),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Administrator account created. Sign in.'),
        ),
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not create the Administrator. Try another username.',
          ),
        ),
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
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                        const FleetIqBrand.wide(),
                        const SizedBox(height: 8),
                        Text(
                          'Create the first Administrator account.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a username'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (value) =>
                              PasswordPolicy.validate(value ?? ''),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmationController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                              ? 'Passwords do not match'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _saving ? null : _submit,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(
                            _saving
                                ? 'Creating Administrator...'
                                : 'Create Administrator',
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
