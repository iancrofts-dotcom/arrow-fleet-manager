import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Web shared central loaders are guarded by resilience runtime', () {
    final source = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(source, contains('CentralResilienceRuntime.instance.run'));
    expect(source, contains('CentralConnectionBoundary'));
    expect(source, contains('shared_dashboard.DashboardScreen'));
    expect(source, contains('CentralDashboardParityService'));
    expect(source, contains('CentralCalendarParityService'));
    expect(source, contains('CentralComplianceParityService'));
  });

  test('runtime resilience integration never introduces SQLite fallback', () {
    final router = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();
    final runtime = File(
      'lib/backend/resilience/central_resilience_runtime.dart',
    ).readAsStringSync();

    for (final source in <String>[router, runtime]) {
      expect(source, isNot(contains('AppDatabase')));
      expect(source, isNot(contains('sqflite')));
      expect(source, isNot(contains('VehicleService')));
      expect(source, isNot(contains('DriverService')));
    }
  });
}
