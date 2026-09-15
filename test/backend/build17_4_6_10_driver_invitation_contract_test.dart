import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Add Driver uses invitation mode and no admin password', () {
    final source = File(
      'lib/features/drivers/screens/add_driver_screen.dart',
    ).readAsStringSync();
    final form = File(
      'lib/features/drivers/widgets/driver_form.dart',
    ).readAsStringSync();

    expect(source, contains('Create Driver & Send Invitation'));
    expect(source, contains('invitationMode: _isCentral'));
    expect(source, contains('_centralRepository.createDriver(driver)'));
    expect(
      source,
      isNot(contains('_centralRepository.createDriver(driver, password:')),
    );
    expect(form, contains('if (!widget.invitationMode)'));
    expect(form, contains('Secure Driver invitation'));
  });

  test(
    'manage-drivers sends Supabase invitation instead of setting password',
    () {
      final source = File(
        'supabase/functions/manage-drivers/index.ts',
      ).readAsStringSync();

      expect(source, contains('inviteUserByEmail'));
      expect(source, contains('FLEETIQ_PASSWORD_REDIRECT_URL'));
      expect(source, isNot(contains('admin.auth.admin.createUser')));
      expect(source, isNot(contains('password: values.password')));
    },
  );

  test('Driver details can resend a secure password setup link', () {
    final source = File(
      'lib/features/drivers/screens/central_driver_details_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Send Password Link'));
    expect(source, contains('CentralPasswordService'));
    expect(source, contains('sendPasswordReset(email)'));
  });
}
