import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native Supabase routes select proven central feature screens', () {
    final source = File(
      'lib/app/router_feature_screens_native.dart',
    ).readAsStringSync();

    expect(source, contains('BackendMode.supabase'));
    expect(source, contains('CentralDashboardParityService'));
    expect(source, contains('CentralCalendarParityService'));
    expect(source, contains('CentralComplianceParityService'));
    expect(source, contains('central_workshop.CentralWorkshopDashboardScreen'));
  });

  test('native local routes retain established local feature screens', () {
    final source = File(
      'lib/app/router_feature_screens_native.dart',
    ).readAsStringSync();

    expect(source, contains('const local_dashboard.DashboardScreen()'));
    expect(source, contains('const local_calendar.CalendarScreen()'));
    expect(source, contains('const local_compliance.ComplianceCentreScreen()'));
    expect(source, contains('const local_workshop.WorkshopDashboardScreen()'));
  });

  test('unknown routes are session protected', () {
    final source = File('lib/app/router.dart').readAsStringSync();
    final onGenerateRoute = source.substring(
      source.indexOf('static Route<dynamic> onGenerateRoute'),
    );

    expect(onGenerateRoute, contains('ProtectedScreen('));
    expect(
      onGenerateRoute,
      contains("AppBar(title: const Text('Page unavailable'))"),
    );
    expect(
      onGenerateRoute,
      isNot(contains("AppBar(title: const Text('Coming Soon'))")),
    );
  });
}
