import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web dashboard uses the shared role-aware central dashboard', () {
    final webRouter = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();
    final sharedDashboard = File(
      'lib/features/dashboard/dashboard_screen.dart',
    ).readAsStringSync();

    expect(
      webRouter,
      contains(
        "import '../features/dashboard/dashboard_screen.dart' as shared_dashboard;",
      ),
    );
    expect(webRouter, contains('shared_dashboard.DashboardScreen('));
    expect(
      webRouter,
      contains('CentralResilienceRuntime.instance.run(service.loadSummary)'),
    );
    expect(webRouter, contains('getFleetHealth: service.getFleetHealth'));
    // The old snapshot DTO is retained only for backwards-compatible platform tests.
    // It must not be wired into the runtime DashboardScreen.
    expect(webRouter, contains('class CentralDashboardSnapshot'));
    expect(webRouter, isNot(contains('_CentralDriverDashboardContent')));

    expect(sharedDashboard, contains('case UserRole.driver:'));
    expect(sharedDashboard, contains('return DashboardRole.driver;'));
    expect(
      sharedDashboard,
      contains(
        "dashboardRole == DashboardRole.driver\n          ? const DriverDashboard()",
      ),
    );
  });
}
