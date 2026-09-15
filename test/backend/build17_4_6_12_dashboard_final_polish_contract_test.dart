import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard keeps one Fleet Health presentation and links Workshop', () {
    final header = File(
      'lib/features/dashboard/widgets/dashboard_header.dart',
    ).readAsStringSync();
    final executive = File(
      'lib/features/dashboard/widgets/executive_dashboard_content.dart',
    ).readAsStringSync();

    expect(header, isNot(contains('Fleet Health')));
    expect(header, isNot(contains('dashboard-fleet-health')));
    expect(executive, contains("title: 'Fleet Health'"));
    expect(executive, contains("title: 'Workshop Operations'"));
    expect(executive, contains("Key('dashboard-open-workshop')"));
    expect(executive, contains("label: const Text('Open Workshop')"));
    expect(executive, contains('DashboardNavigation.openWorkshop(context)'));
    expect(executive, contains('PermissionService.instance.canAccessWorkshop'));
  });
}
