import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../shared/widgets/fleetiq_brand.dart';
import '../invitation/invitation_url_sanitizer.dart';
import '../services/invitation_password_gateway.dart';
import '../services/password_policy.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key, this.gateway});

  final InvitationPasswordGateway? gateway;

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

enum _InvitationState { checking, ready, invalid, submitting, success, error }

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  late final InvitationPasswordGateway _gateway;
  _InvitationState _state = _InvitationState.checking;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? SupabaseInvitationPasswordGateway();
    _checkSession();
  }

  Future<void> _checkSession() async {
    var valid = false;
    try {
      valid = await _gateway.hasInvitationSession();
    } catch (_) {
      valid = false;
    } finally {
      // Supabase initialization has already consumed the callback by this point.
      sanitizeInvitationUrl();
    }
    if (mounted) {
      setState(
        () =>
            _state = valid ? _InvitationState.ready : _InvitationState.invalid,
      );
    }
  }

  Future<void> _submit() async {
    if (_state == _InvitationState.submitting ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _state = _InvitationState.submitting);
    try {
      await _gateway.updatePassword(_passwordController.text);
      if (mounted) setState(() => _state = _InvitationState.success);
    } catch (_) {
      if (mounted) setState(() => _state = _InvitationState.error);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.appBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FleetIqBrand.wide(height: 64),
                      const SizedBox(height: 28),
                      ..._content(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context) => switch (_state) {
    _InvitationState.checking => const [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Checking your secure password link…'),
    ],
    _InvitationState.invalid => [
      Text(
        'Invitation unavailable',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'This secure password link is invalid, expired, or has already been used. Request a new password-reset link from the FleetIQ sign-in screen.',
        textAlign: TextAlign.center,
      ),
    ],
    _InvitationState.success => [
      const Icon(Icons.check_circle, color: Colors.green, size: 48),
      const SizedBox(height: 16),
      Text('Password set', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      const Text(
        'Your FleetIQ password is ready. Sign in with your email and new password.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () =>
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
        child: const Text('Continue to FleetIQ'),
      ),
    ],
    _ => [
      Text(
        'Set your password',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'Create a new password for your FleetIQ account.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('new-password'),
              controller: _passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) => PasswordPolicy.validate(value ?? ''),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('confirm-password'),
              controller: _confirmationController,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (value) => value == _passwordController.text
                  ? null
                  : 'Passwords do not match.',
            ),
            if (_state == _InvitationState.error) ...[
              const SizedBox(height: 16),
              const Text(
                'We could not set your password. The secure link may have expired. Please request a new password-reset link and try again.',
                key: Key('safe-password-error'),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _state == _InvitationState.submitting
                    ? null
                    : _submit,
                child: _state == _InvitationState.submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Set password'),
              ),
            ),
          ],
        ),
      ),
    ],
  };
}
