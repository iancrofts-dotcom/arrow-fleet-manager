import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Driver Management creates linked portal accounts safely', () {
    final function = File(
      'supabase/functions/manage-drivers/index.ts',
    ).readAsStringSync();
    final list = File(
      'lib/features/drivers/screens/driver_list_screen.dart',
    ).readAsStringSync();
    final add = File(
      'lib/features/drivers/screens/add_driver_screen.dart',
    ).readAsStringSync();

    expect(function, contains("['administrator', 'manager']"));
    expect(function, contains("role: 'driver'"));
    expect(function, contains('driver_id: driverId'));
    expect(function, contains(".from('driver_assignments')"));
    expect(
      function,
      contains(
        'End the current vehicle assignment before deactivating this Driver.',
      ),
    );
    expect(list, contains('CentralDriverManagementRepository'));
    expect(
      add,
      contains(
        'Create a Driver profile and send a secure invitation for them to set their own password.',
      ),
    );
    expect(add, contains('Create Driver & Send Invitation'));
    expect(add, contains('invitationMode: _isCentral'));
  });

  test('central Driver Management never enables assignment mutation', () {
    final function = File(
      'supabase/functions/manage-drivers/index.ts',
    ).readAsStringSync();

    expect(function, isNot(contains(".from('driver_assignments').insert")));
    expect(function, isNot(contains(".from('driver_assignments').update")));
    expect(function, isNot(contains(".from('driver_assignments').delete")));
  });
}
