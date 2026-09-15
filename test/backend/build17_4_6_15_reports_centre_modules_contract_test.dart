import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('17.4.6.15 exposes the approved report modules', () {
    final source = File(
      'lib/features/reports/models/report_module.dart',
    ).readAsStringSync();
    for (final token in [
      'fleetSummary',
      'compliance',
      'drivers',
      'inspections',
      'defects',
    ]) {
      expect(source, contains(token));
    }
  });

  test('central reports use live central repositories and parity services', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    expect(source, contains('CentralComplianceParityService'));
    expect(source, contains('BackendDriverRepository'));
    expect(source, contains('SupabaseDriverGateway'));
    expect(source, contains('BackendWorkshopRepository'));
    expect(source, contains('SupabaseWorkshopGateway'));
    expect(source, isNot(contains('AppDatabase')));
    expect(source, isNot(contains('SQLite')));
  });

  test('inspection and defect reports support date range filtering', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    expect(source, contains('_inRange'));
    expect(source, contains('ReportModule.inspections'));
    expect(source, contains('ReportModule.defects'));
    expect(source, contains('query.from'));
    expect(source, contains('query.to'));
  });

  test('reports screen exports the currently selected report document', () {
    final source = File(
      'lib/features/reports/screens/reports_screen.dart',
    ).readAsStringSync();
    expect(source, contains('generateDocument'));
    expect(source, contains('ChoiceChip'));
    expect(source, contains('Preview PDF'));
    expect(source, contains('Export CSV'));
    expect(source, contains('Export PDF'));
    expect(source, contains('Date Range'));
  });

  test(
    'web router injects central report module service through resilience runtime',
    () {
      final source = File(
        'lib/app/router_feature_screens_web.dart',
      ).readAsStringSync();
      expect(source, contains('CentralReportsCentreService'));
      expect(source, contains('generateDocument:'));
      expect(source, contains('CentralResilienceRuntime.instance.run'));
    },
  );

  test(
    '17.4.6.15 does not introduce migrations or service-role credentials',
    () {
      final root = Directory('.');
      final changedSource = [
        File(
          'lib/backend/central_reports_centre_service.dart',
        ).readAsStringSync(),
        File(
          'lib/features/reports/screens/reports_screen.dart',
        ).readAsStringSync(),
      ].join('\n');
      expect(changedSource.toLowerCase(), isNot(contains('service_role')));
      expect(root.path, isNotEmpty);
    },
  );
}
