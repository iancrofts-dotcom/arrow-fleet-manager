import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'assignment mutations use secured RPCs and preserve direct-write lock',
    () {
      final gateway = File(
        'lib/backend/drivers/supabase_driver_assignment_gateway.dart',
      ).readAsStringSync();
      final migration = File(
        'supabase/migrations/20260909164000_assignment_operational_writes.sql',
      ).readAsStringSync();
      expect(gateway, contains("'fleet_assign_driver'"));
      expect(gateway, contains("'fleet_end_driver_assignment'"));
      expect(migration, contains('security definer'));
      expect(migration, contains("has_fleetiq_role('administrator')"));
      expect(migration, contains("has_fleetiq_role('manager')"));
      expect(migration, contains('revoke insert, update, delete'));
      expect(
        migration,
        contains('driver_id = p_driver_id or vehicle_id = p_vehicle_id'),
      );
      expect(migration, contains('assigned_to = greatest'));
    },
  );

  test('central Driver and Vehicle details expose assignment management', () {
    final driver = File(
      'lib/features/drivers/screens/central_driver_details_screen.dart',
    ).readAsStringSync();
    final vehicle = File(
      'lib/features/vehicles/widgets/central_vehicle_assignments_section.dart',
    ).readAsStringSync();
    expect(driver, contains('Assign / Change Vehicle'));
    expect(driver, contains('End Current Assignment'));
    expect(vehicle, contains('Assign / Change Driver'));
    expect(vehicle, contains('End Current Assignment'));
  });

  test('central Workshop restores original operational dashboard surfaces', () {
    final source = File(
      'lib/features/workshop/screens/central_workshop_dashboard_screen.dart',
    ).readAsStringSync();
    for (final label in <String>[
      'Quick Actions',
      'New Inspection',
      'Inspection Templates',
      'Inspection List',
      'Repair Jobs',
      'Workshop Reports',
      'Open Inspections',
      'Completed Today',
      'Critical Failures',
      'Repairs Required',
      'Repairs Outstanding',
      'Awaiting Parts',
      'Awaiting Sign-off',
      'Recent Activity',
    ]) {
      expect(
        source,
        contains(label),
        reason: 'Missing Workshop surface: $label',
      );
    }
    expect(source, contains('SupabaseWorkshopGateway'));
  });
}
