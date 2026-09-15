import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Build 15 central Driver compliance is self-scoped and assignment-safe',
    () {
      final sql = File(
        'supabase/migrations/20260909150000_driver_compliance_and_document_writes.sql',
      ).readAsStringSync();
      final screen = File(
        'lib/features/drivers/screens/central_driver_compliance_screen.dart',
      ).readAsStringSync();

      expect(
        sql,
        contains('create table if not exists public.driver_compliance'),
      );
      expect(sql, contains('fleet_save_driver_compliance'));
      expect(sql, contains("public.has_fleetiq_role('driver')"));
      expect(sql, contains('v_own_driver_id = p_driver_id'));
      expect(sql, contains('taxi_licence_number'));
      expect(sql, contains('taxi_licence_expiry'));
      expect(sql, isNot(contains('insert into public.driver_assignments')));
      expect(sql, isNot(contains('update public.driver_assignments')));
      expect(sql, isNot(contains('delete from public.driver_assignments')));
      expect(screen, contains('Your central compliance record'));
      expect(screen, contains('Taxi / Private Hire Licence Number'));
    },
  );

  test(
    'Build 15 Driver documents permit only the signed-in Driver namespace',
    () {
      final sql = File(
        'supabase/migrations/20260909150000_driver_compliance_and_document_writes.sql',
      ).readAsStringSync();
      final edit = File(
        'lib/features/documents/screens/central_edit_document_screen.dart',
      ).readAsStringSync();
      final dashboard = File(
        'lib/features/dashboard/sections/role_sections/driver_dashboard.dart',
      ).readAsStringSync();

      expect(sql, contains("split_part(name,'/',1)='driver'"));
      expect(
        sql,
        contains(
          'select driver_id::text from public.profiles where id=auth.uid()',
        ),
      );
      expect(sql, contains('v_own_driver_id=p_entity_id'));
      expect(edit, contains('currentBackendDriverId'));
      expect(edit, contains("_entityType = 'driver'"));
      expect(dashboard, contains("title: 'My Compliance'"));
      expect(dashboard, contains("title: 'My Documents'"));
    },
  );

  test('central Fleet Vehicle and Driver details expose central Documents', () {
    final vehicle = File(
      'lib/features/vehicles/screens/vehicle_details_screen.dart',
    ).readAsStringSync();
    final driver = File(
      'lib/features/drivers/screens/central_driver_details_screen.dart',
    ).readAsStringSync();

    expect(vehicle, contains("initialFilter: 'Vehicle'"));
    expect(vehicle, contains('Vehicle Documents'));
    expect(driver, contains("initialFilter: 'Driver'"));
    expect(driver, contains("label: const Text('Documents')"));
    expect(driver, contains("label: const Text('Compliance')"));
  });
}
