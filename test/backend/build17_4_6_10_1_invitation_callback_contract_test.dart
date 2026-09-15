import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invitation callback waits for Supabase auth session restoration', () {
    final gateway = File(
      'lib/features/auth/services/invitation_password_gateway.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/auth/screens/set_password_screen.dart',
    ).readAsStringSync();

    expect(gateway, contains('_client.auth.onAuthStateChange.listen'));
    expect(gateway, contains('Duration(seconds: 5)'));
    expect(gateway, contains('_client.auth.currentSession'));
    expect(gateway, contains('await subscription.cancel()'));
    expect(screen, contains('sanitizeInvitationUrl();'));
  });
}
