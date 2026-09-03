import 'dart:async';

import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:arrow_fleet_manager/features/dashboard/services/dashboard_refresh_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _summary = DashboardSummary(
  vehicleCount: 1,
  driverCount: 1,
  activeVehicles: 1,
  activeDrivers: 1,
  assignedDrivers: 0,
  unassignedDrivers: 1,
  assignedVehicles: 0,
  unassignedVehicles: 1,
  maintenanceDue: 0,
  maintenanceOverdue: 0,
  complianceDue: 0,
  complianceExpired: 0,
  recentActivity: [],
  alerts: [],
);

void main() {
  test('initial load publishes the first dashboard summary', () async {
    final summaries = <DashboardSummary>[];
    final errors = <Object>[];
    final controller = DashboardRefreshController(
      loadSummary: () async => _summary,
      onData: summaries.add,
      onInitialError: errors.add,
    );

    await controller.loadInitial();

    expect(summaries, [_summary]);
    expect(errors, isEmpty);
  });

  test(
    'a failed background refresh retains the last successful summary',
    () async {
      var loadCount = 0;
      final summaries = <DashboardSummary>[];
      final errors = <Object>[];
      final controller = DashboardRefreshController(
        loadSummary: () async {
          loadCount++;
          if (loadCount == 1) {
            return _summary;
          }
          throw StateError('Temporary refresh failure');
        },
        onData: summaries.add,
        onInitialError: errors.add,
      );

      await controller.loadInitial();
      await controller.refresh();

      expect(summaries, [_summary]);
      expect(errors, isEmpty);
    },
  );

  test('overlapping refresh requests use one dashboard load', () async {
    final completer = Completer<DashboardSummary>();
    var loadCount = 0;
    final controller = DashboardRefreshController(
      loadSummary: () {
        loadCount++;
        return completer.future;
      },
      onData: (_) {},
      onInitialError: (_) {},
    );

    final firstRefresh = controller.refresh();
    final secondRefresh = controller.refresh();

    expect(loadCount, 1);
    expect(controller.isRefreshing, isTrue);

    completer.complete(_summary);
    await Future.wait([firstRefresh, secondRefresh]);

    expect(controller.isRefreshing, isFalse);
  });

  testWidgets('periodic refresh pauses while inactive and stops on dispose', (
    tester,
  ) async {
    var loadCount = 0;
    final controller = DashboardRefreshController(
      loadSummary: () async {
        loadCount++;
        return _summary;
      },
      onData: (_) {},
      onInitialError: (_) {},
      interval: const Duration(seconds: 1),
    )..startPeriodicRefresh();

    controller.setActive(false);
    await tester.pump(const Duration(seconds: 2));
    expect(loadCount, 0);

    controller.setActive(true);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(loadCount, 1);

    controller.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(loadCount, 1);
  });
}
