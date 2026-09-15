import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web dashboard delegates to the shared role-aware dashboard', () {
    final webRouter = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();
    final dashboard = File(
      'lib/features/dashboard/dashboard_screen.dart',
    ).readAsStringSync();

    expect(webRouter, contains('shared_dashboard.DashboardScreen'));
    expect(
      webRouter,
      contains('CentralResilienceRuntime.instance.run(service.loadSummary)'),
    );
    expect(webRouter, isNot(contains('Central fleet overview')));
    expect(webRouter, isNot(contains('Central migration status')));
    expect(dashboard, contains('DashboardRole.administrator'));
    expect(dashboard, contains('_buildFleetDashboard(dashboardRole)'));
  });

  test('Driver walkaround preloads the latest mileage without locking it', () {
    final screen = File(
      'lib/features/inspections/inspection_screen.dart',
    ).readAsStringSync();
    final details = File(
      'lib/features/inspections/widgets/inspection_details_section.dart',
    ).readAsStringSync();
    final centralService = File(
      'lib/features/inspections/services/central_driver_daily_inspection_service.dart',
    ).readAsStringSync();

    // Keep this contract resilient to dart format line wrapping. The method
    // name, service call and assignment together prove the prefill path exists.
    expect(screen, contains('_prefillCentralMileage'));
    expect(screen, contains('_centralDailyInspectionService.latestMileage('));
    expect(screen, contains('mileageController.text = mileage.toString()'));
    expect(screen, contains('lockDriver: driverNeedsLockedInspection'));
    expect(screen, contains('lockedVehicle: driverNeedsLockedInspection'));
    expect(details, contains("labelText: 'Odometer'"));
    expect(details, isNot(contains('readOnly: true')));
    expect(centralService, contains(".from('workshop_inspections')"));
    expect(
      centralService,
      contains(".order('date_started', ascending: false)"),
    );
    expect(centralService, contains('.limit(1)'));
  });
}
