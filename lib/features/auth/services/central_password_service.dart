import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../backend/backend_client.dart';
import 'password_policy.dart';

class CentralPasswordService {
  const CentralPasswordService();

  static const _configuredRedirect = String.fromEnvironment(
    'FLEETIQ_PASSWORD_REDIRECT_URL',
    defaultValue: 'https://fleetiq.unaux.com/app/?route=set-password',
  );

  Future<void> changePassword({required String newPassword}) async {
    final validation = PasswordPolicy.validate(newPassword);
    if (validation != null) {
      throw ArgumentError(validation);
    }
    if (BackendClient.client.auth.currentUser == null) {
      throw StateError('You must be signed in to change your password.');
    }
    await BackendClient.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> sendPasswordReset(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw ArgumentError('Enter the email address used for FleetIQ.');
    }
    await BackendClient.client.auth.resetPasswordForEmail(
      normalized,
      redirectTo: _passwordRedirect(),
    );
  }

  String _passwordRedirect() => _configuredRedirect;
}
