import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Driver login retains linked Driver UUID', () {
    final source = File(
      'lib/features/auth/services/auth_service.dart',
    ).readAsStringSync();

    expect(source, contains('_currentBackendDriverId = profile.driverId'));
    expect(source, contains('currentBackendDriverId'));
  });

  test('Driver dashboard uses central assignment reads in Supabase mode', () {
    final source = File(
      'lib/features/dashboard/sections/role_sections/driver_dashboard.dart',
    ).readAsStringSync();

    expect(source, contains('BackendMode.supabase'));
    expect(source, contains('CentralDriverWorkspaceService'));
    expect(source, contains('currentBackendDriverId'));
  });

  test(
    'central Driver workspace keeps assignment reads while writes use secured RPCs',
    () {
      final gateway = File(
        'lib/backend/drivers/supabase_driver_assignment_gateway.dart',
      ).readAsStringSync();

      expect(gateway, contains('listAssignmentsForDriver'));
      expect(gateway, contains("'fleet_assign_driver'"));
      expect(gateway, contains("'fleet_end_driver_assignment'"));
    },
  );
}
