import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dashboard polish preserves shared central Dashboard architecture', () {
    final dashboard = File(
      'lib/features/dashboard/dashboard_screen.dart',
    ).readAsStringSync();

    expect(dashboard, contains('DashboardPolishScope'));
    expect(dashboard, contains('DashboardRouter.build'));
    expect(dashboard, contains('DashboardContext('));
    expect(dashboard, contains('loadSummary'));
    expect(dashboard, contains('getFleetHealth'));
    expect(dashboard, isNot(contains('AppDatabase')));
    expect(dashboard, isNot(contains('sqflite')));
  });

  test(
    'Dashboard polish is visual-only and uses existing Material palette',
    () {
      final polish = File(
        'lib/features/dashboard/widgets/dashboard_polish_scope.dart',
      ).readAsStringSync();

      expect(polish, contains('Theme.of(context)'));
      expect(polish, contains('base.copyWith'));
      expect(polish, contains('cardTheme'));
      expect(polish, contains('listTileTheme'));
      expect(polish, contains('textTheme'));
      expect(polish, isNot(contains('Navigator.')));
      expect(polish, isNot(contains('Supabase')));
      expect(polish, isNot(contains('AppDatabase')));
    },
  );

  test('Web continues to inject resilient central dashboard loaders', () {
    final router = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(router, contains('shared_dashboard.DashboardScreen'));
    expect(router, contains('CentralDashboardParityService'));
    expect(router, contains('CentralResilienceRuntime.instance.run'));
    expect(router, contains('getFleetHealth: service.getFleetHealth'));
  });
}
