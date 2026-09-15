import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('17.4.6.11 dashboard is responsive and uses existing summary data', () {
    final source = File(
      'lib/features/dashboard/widgets/executive_dashboard_content.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'Vehicles'"));
    expect(source, contains("title: 'Drivers'"));
    expect(source, contains("title: 'MOT Due'"));
    expect(source, contains("title: 'Service Due'"));
    expect(source, contains("title: 'Overdue'"));
    expect(source, contains("title: 'Open Defects'"));
    expect(source, contains("title: 'Fleet Health'"));
    expect(source, contains("title: 'Fleet Allocation'"));
    expect(source, contains("title: 'Upcoming & Attention'"));
    expect(source, contains("title: 'Workshop Operations'"));
    expect(source, contains("title: 'Recent Activity'"));
    expect(source, contains("title: 'Operational Snapshot'"));
    expect(source, contains('CustomPaint('));
    expect(source, contains('LinearProgressIndicator('));
    expect(source, contains('constraints.maxWidth >= 1180'));
    expect(source, contains('constraints.maxWidth < 700'));
    expect(source, isNot(contains('lorry')));
    expect(source, isNot(contains('truck image')));
    expect(source, isNot(contains('NetworkImage')));
    expect(source, isNot(contains('Image.network')));
  });

  test('17.4.6.11 keeps DashboardContent entry point stable', () {
    final source = File(
      'lib/features/dashboard/widgets/dashboard_content.dart',
    ).readAsStringSync();

    expect(source, contains('class DashboardContent extends StatelessWidget'));
    expect(source, contains('ExecutiveDashboardContent('));
    expect(source, contains('dashboardContext: this.context'));
  });
}
