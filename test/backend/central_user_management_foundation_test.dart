import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central User Management is membership scoped and invitation based', () {
    final form = File(
      'lib/features/auth/widgets/central/central_user_form.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/auth/screens/central/central_user_management_screen.dart',
    ).readAsStringSync();
    final function = File(
      'supabase/functions/manage-users/index.ts',
    ).readAsStringSync();

    expect(form, contains('UserRole.technician'));
    expect(form, contains("labelText: 'Email *'"));
    expect(form, contains('Administrators never set user passwords'));
    expect(screen, contains('Add / Invite User'));
    expect(function, contains("membership.role !== 'administrator'"));
    expect(function, contains("nextRole === 'driver'"));
    expect(
      function,
      contains('At least one active Administrator is required.'),
    );
    expect(function, contains('inviteUserByEmail'));
    expect(function, contains('SUPABASE_SERVICE_ROLE_KEY'));
  });

  test('central user-management service role remains server-side', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('SUPABASE_SERVICE_ROLE_KEY')),
        reason: 'Service-role secret must not be referenced by ${file.path}',
      );
    }
  });
}
