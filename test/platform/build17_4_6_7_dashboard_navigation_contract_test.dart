import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dashboard navigation uses protected central destinations', () {
    final navigation = File(
      'lib/core/navigation/dashboard_navigation.dart',
    ).readAsStringSync();

    expect(navigation, contains("Navigator.pushNamed(context, '/workshop')"));
    expect(navigation, contains("Navigator.pushNamed(context, '/compliance')"));

    expect(navigation, contains("case '/maintenance':"));
    expect(navigation, contains('return openWorkshop(context);'));
    expect(navigation, contains("case '/workshop':"));
    expect(navigation, contains("case '/compliance':"));
    expect(navigation, contains('return openCompliance(context);'));

    expect(navigation, contains('permissions.canAccessWorkshop'));
    expect(navigation, contains('permissions.canViewCompliance'));

    final workshopStart = navigation.indexOf(
      'static Future<void> openWorkshop',
    );
    final documentsStart = navigation.indexOf(
      'static Future<void> openDocuments',
      workshopStart,
    );
    final workshopMethod = navigation.substring(workshopStart, documentsStart);
    expect(workshopMethod, isNot(contains('VehicleFilter.workshop')));

    final complianceStart = navigation.indexOf(
      'static Future<void> openCompliance',
    );
    final complianceMethod = navigation.substring(complianceStart);
    expect(
      complianceMethod,
      isNot(contains('ComplianceCentreScreen')),
      reason:
          'Dashboard Compliance must go through AppRouter so Web resolves '
          'the central platform-aware screen.',
    );
  });

  test('AppRouter protects Workshop and Compliance destinations', () {
    final router = File('lib/app/router.dart').readAsStringSync();

    expect(router, contains("static const String workshop = '/workshop'"));
    expect(router, contains("static const String compliance = '/compliance'"));
    expect(router, contains('permissions.canAccessWorkshop'));
    expect(router, contains('permissions.canViewCompliance'));
    expect(router, contains('WorkshopDashboardScreen'));
    expect(router, contains('ComplianceCentreScreen'));
  });

  test('primary Dashboard Compliance KPI is actionable', () {
    final kpis = File(
      'lib/features/dashboard/sections/dashboard_kpi_section.dart',
    ).readAsStringSync();

    expect(
      kpis,
      anyOf(
        contains("Navigator.pushNamed(context, '/compliance')"),
        contains('DashboardNavigation.openCompliance(context)'),
      ),
    );

    expect(
      kpis,
      anyOf(
        contains('DashboardNavigation.openWorkshop(context)'),
        contains("Navigator.pushNamed(context, '/workshop')"),
      ),
    );
  });

  test('Web route layer still owns central Dashboard and destinations', () {
    final web = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(web, contains('shared_dashboard.DashboardScreen'));
    expect(web, contains('CentralDashboardParityService'));
    expect(web, contains('CentralResilienceRuntime.instance.run'));
    expect(web, contains('ComplianceCentreScreen'));
    expect(web, contains('WorkshopDashboardScreen'));
  });
}
