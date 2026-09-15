import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String dashboard;
  late String entryPoint;

  setUpAll(() {
    dashboard = File(
      'lib/features/dashboard/widgets/executive_dashboard_content.dart',
    ).readAsStringSync();
    entryPoint = File(
      'lib/features/dashboard/widgets/dashboard_content.dart',
    ).readAsStringSync();
  });

  test('approved 17.4.6.11 primary KPIs are present without old KPI shell', () {
    for (final title in <String>[
      'Vehicles',
      'Drivers',
      'MOT Due',
      'Service Due',
      'Overdue',
      'Open Defects',
    ]) {
      expect(dashboard, contains("title: '$title'"));
    }

    expect(dashboard, isNot(contains('DashboardKpiSection')));
    expect(dashboard, isNot(contains('dashboard-kpi-fleet')));
    expect(dashboard, isNot(contains('Registered drivers')));
  });

  test(
    'approved information panels are present once in the dashboard source',
    () {
      for (final title in <String>[
        'Fleet Health',
        'Fleet Allocation',
        'Upcoming & Attention',
        'Workshop Operations',
        'Recent Activity',
        'Operational Snapshot',
      ]) {
        final marker = "title: '$title'";
        expect(dashboard, contains(marker));
        expect(marker.allMatches(dashboard).length, 1);
      }

      expect(dashboard, isNot(contains("title: 'Fleet Operations'")));
      expect(dashboard, isNot(contains('Priority Centre')));
    },
  );

  test('dashboard keeps one stable DashboardContent entry point', () {
    expect(
      entryPoint,
      contains('class DashboardContent extends StatelessWidget'),
    );
    expect(entryPoint, contains('ExecutiveDashboardContent('));
    expect(entryPoint, contains('dashboardContext: this.context'));
  });

  test('phone and tablet layouts use responsive stacking rules', () {
    expect(dashboard, contains('final mobile = constraints.maxWidth < 700;'));
    expect(dashboard, contains('final tablet = constraints.maxWidth < 1080;'));
    expect(dashboard, contains('if (tablet)'));
    expect(dashboard, contains('if (mobile)'));
    expect(dashboard, contains('constraints.maxWidth < 700 ? 10.0 : 14.0'));
  });

  test('KPI grid adapts from two to three to six columns', () {
    expect(dashboard, contains('constraints.maxWidth >= 1180'));
    expect(dashboard, contains('constraints.maxWidth >= 760'));
    expect(
      dashboard,
      contains('(constraints.maxWidth - (spacing * (columns - 1))) / columns'),
    );
  });

  test(
    'desktop dashboard caps content width and avoids horizontal scrolling',
    () {
      expect(
        dashboard,
        contains('constraints: const BoxConstraints(maxWidth: 1440)'),
      );
      expect(dashboard, contains('SingleChildScrollView('));
      expect(dashboard, contains('AlwaysScrollableScrollPhysics()'));
      expect(dashboard, isNot(contains('scrollDirection: Axis.horizontal')));
    },
  );

  test('charts use existing summary data rather than extra repositories', () {
    expect(dashboard, contains('CustomPaint('));
    expect(dashboard, contains('LinearProgressIndicator('));
    expect(dashboard, contains('final DashboardContext dashboardContext;'));
    expect(
      dashboard,
      contains('DashboardSummary get summary => dashboardContext.summary;'),
    );
    expect(
      dashboard,
      contains('FleetHealth get fleetHealth => dashboardContext.fleetHealth;'),
    );
    expect(dashboard, isNot(contains('Repository(')));
    expect(dashboard, isNot(contains('Supabase')));
  });

  test('dashboard contains no decorative vehicle image dependency', () {
    expect(dashboard.toLowerCase(), isNot(contains('lorry')));
    expect(dashboard, isNot(contains('NetworkImage')));
    expect(dashboard, isNot(contains('Image.network')));
  });
}
