import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central vehicles persist PSV and Taxi safety schedules', () {
    final migration = File(
      'supabase/migrations/20260911123000_fleet_compliance_safety_schedules.sql',
    ).readAsStringSync();
    final vehicle = File(
      'lib/backend/vehicles/backend_vehicle.dart',
    ).readAsStringSync();

    expect(migration, contains('mot_type'));
    expect(migration, contains('psv_garage_check_interval_weeks'));
    expect(migration, contains('taxi_safety_check_interval_weeks'));
    expect(migration, contains("check (mot_type in ('standard', 'psv'))"));
    expect(vehicle, contains('psvGarageCheckDue'));
    expect(vehicle, contains('taxiSafetyCheckDue'));
  });

  test('calendar includes statutory dates and outstanding vehicle issues', () {
    final calendar = File(
      'lib/backend/central_calendar_parity_service.dart',
    ).readAsStringSync();

    expect(calendar, contains('PSV MOT Due'));
    expect(calendar, contains('PSV Garage Check Due'));
    expect(calendar, contains('Taxi Safety Check Due'));
    expect(calendar, contains('Vehicle Licence (Taxi) Expiry'));
    expect(calendar, contains('Driving Licence Expiry'));
    expect(calendar, contains('CPC Expiry'));
    expect(calendar, contains('Medical Expiry'));
    expect(calendar, contains('Vehicle Issue •'));
    expect(calendar, contains('listRepairJobs'));
  });

  test('compliance centre exposes a full Driver and Vehicle register', () {
    final model = File(
      'lib/features/compliance/models/fleet_compliance_summary.dart',
    ).readAsStringSync();
    final central = File(
      'lib/backend/central_compliance_parity_service.dart',
    ).readAsStringSync();
    final content = File(
      'lib/features/compliance/widgets/compliance_centre_content.dart',
    ).readAsStringSync();

    expect(model, contains('allItems'));
    expect(model, contains('psvGarageCheck'));
    expect(model, contains('taxiSafetyCheck'));
    expect(central, contains('FleetComplianceCheckType.psvMot'));
    expect(central, contains('FleetComplianceCheckType.taxiLicence'));
    expect(content, contains('All Compliance Records'));
    expect(content, contains('Vehicle Licence (Taxi)'));
    expect(content, contains('Taxi / Private Hire Licence'));
  });

  test(
    'Web delegates Calendar and Compliance to the shared central parity screens',
    () {
      final web = File(
        'lib/app/router_feature_screens_web.dart',
      ).readAsStringSync();

      expect(
        web,
        contains('CentralResilienceRuntime.instance.run(service.loadEvents)'),
      );
      expect(
        web,
        contains('CentralResilienceRuntime.instance.run(service.loadSummary)'),
      );
      expect(web, contains('CentralComplianceNavigation.openAttention'));
    },
  );
}
