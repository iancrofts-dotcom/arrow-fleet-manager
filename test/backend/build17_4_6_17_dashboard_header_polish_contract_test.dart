import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard omits personal greeting card and starts with KPI grid', () {
    final executive = File(
      'lib/features/dashboard/widgets/executive_dashboard_content.dart',
    ).readAsStringSync();

    expect(executive, isNot(contains("import 'dashboard_header.dart';")));
    expect(executive, isNot(contains('const DashboardHeader()')));
    expect(executive, contains("Key('dashboard-primary-kpi-grid')"));

    // Preserve the approved operational panels and Workshop navigation.
    expect(executive, contains("title: 'Fleet Health'"));
    expect(executive, contains("title: 'Fleet Allocation'"));
    expect(executive, contains("title: 'Upcoming & Attention'"));
    expect(executive, contains("title: 'Workshop Operations'"));
    expect(executive, contains("title: 'Recent Activity'"));
    expect(executive, contains("title: 'Operational Snapshot'"));
    expect(executive, contains('DashboardNavigation.openWorkshop(context)'));
  });
}
