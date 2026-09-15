import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native central mode reuses original FleetIQ feature screens', () {
    final router = File(
      'lib/app/router_feature_screens_native.dart',
    ).readAsStringSync();

    expect(router, contains("features/dashboard/dashboard_screen.dart"));
    expect(router, contains("features/calendar/screens/calendar_screen.dart"));
    expect(
      router,
      contains("features/compliance/screens/compliance_centre_screen.dart"),
    );
    expect(router, contains("features/reports/screens/reports_screen.dart"));
    expect(router, contains('CentralDashboardParityService'));
    expect(router, contains('CentralCalendarParityService'));
    expect(router, contains('CentralComplianceParityService'));
    expect(router, contains('CentralFleetReportService'));
  });

  test('central Users and Documents are supported routes', () {
    final capabilities = File(
      'lib/platform/platform_capabilities.dart',
    ).readAsStringSync();
    final webRouter = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(capabilities, contains("'/users'"));
    expect(capabilities, contains("'/documents'"));
    expect(webRouter, contains('CentralUserManagementScreen'));
    expect(webRouter, contains("driver_list_screen.dart"));
  });

  test('technician Workshop navigation goes through protected route', () {
    final technician = File(
      'lib/features/dashboard/sections/role_sections/technician_dashboard.dart',
    ).readAsStringSync();

    expect(technician, contains("Navigator.pushNamed(context, '/workshop')"));
    expect(technician, isNot(contains('WorkshopDashboardScreen(')));
  });
}
