import 'package:flutter/material.dart';

import '../../../shared/widgets/form_section.dart';
import '../../auth/services/password_policy.dart';

class LoginDetailsSection extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showPasswordFields;

  const LoginDetailsSection({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    this.showPasswordFields = true,
  });

  @override
  State<LoginDetailsSection> createState() => _LoginDetailsSectionState();
}

class _LoginDetailsSectionState extends State<LoginDetailsSection> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Login Details',
      subtitle: 'Credentials used to sign in to the Driver Portal.',
      child: Column(
        children: [
          TextFormField(
            controller: widget.usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a username';
              }
              return null;
            },
          ),

          if (widget.showPasswordFields) ...[
            const SizedBox(height: 16),

            TextFormField(
              controller: widget.passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a password';
                }

                return PasswordPolicy.validate(value);
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: widget.confirmPasswordController,
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value != widget.passwordController.text) {
                  return 'Passwords do not match';
                }

                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
