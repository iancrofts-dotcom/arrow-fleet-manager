import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Driver daily inspection uses secured RPC', () {
    final source = File(
      'lib/features/inspections/services/central_driver_daily_inspection_service.dart',
    ).readAsStringSync();
    expect(source, contains("'workshop_save_driver_daily_inspection'"));
    expect(source, isNot(contains(".from('workshop_inspections').insert")));
  });

  test('central Driver inspection gate uses central Driver UUID', () {
    final source = File(
      'lib/features/inspections/inspection_screen.dart',
    ).readAsStringSync();
    expect(source, contains('currentBackendDriverId'));
    expect(source, contains('CentralDriverDailyInspectionService'));
  });

  test(
    'migration scopes assigned vehicle access to current Driver assignment',
    () {
      final source = File(
        'supabase/migrations/20260910064500_driver_assigned_vehicle_and_daily_inspection.sql',
      ).readAsStringSync();
      expect(source, contains('drivers read current assigned vehicle'));
      expect(source, contains('assignment.driver_id = profile.driver_id'));
      expect(source, contains('assignment.is_active = true'));
      expect(source, contains('workshop_save_driver_daily_inspection'));
    },
  );
}
