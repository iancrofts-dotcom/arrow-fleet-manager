import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_context.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/fleet_health.dart';
import 'package:arrow_fleet_manager/features/dashboard/sections/dashboard_kpi_section.dart';
import 'package:arrow_fleet_manager/features/dashboard/sections/quick_actions_section.dart';
import 'package:arrow_fleet_manager/features/dashboard/widgets/dashboard_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _dashboardContext = DashboardContext(
  summary: DashboardSummary(
    vehicleCount: 8,
    driverCount: 4,
    activeVehicles: 8,
    activeDrivers: 4,
    assignedDrivers: 3,
    unassignedDrivers: 1,
    assignedVehicles: 3,
    unassignedVehicles: 5,
    maintenanceDue: 2,
    maintenanceOverdue: 1,
    complianceDue: 2,
    complianceExpired: 1,
    recentActivity: [],
    alerts: [],
  ),
  fleetHealth: FleetHealth(
    score: 92,
    status: FleetHealthStatus.excellent,
    healthyVehicles: 7,
    warningVehicles: 1,
    criticalVehicles: 0,
  ),
  onRefresh: _refresh,
);

void main() {
  testWidgets('Quick Actions render before the core KPI section', (
    tester,
  ) async {
    await _pumpDashboard(tester, 1000);

    expect(find.byType(QuickActionsSection), findsOneWidget);
    expect(find.byType(DashboardKpiSection), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(QuickActionsSection)).dy,
      lessThan(tester.getTopLeft(find.byType(DashboardKpiSection)).dy),
    );
    expect(find.text('Priority Centre'), findsOneWidget);
  });

  for (final width in [700.0, 1000.0, 1280.0]) {
    testWidgets('Dashboard renders without overflow at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpDashboard(tester, width);

      expect(find.byType(QuickActionsSection), findsOneWidget);
      expect(find.byType(DashboardKpiSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _refresh() async {}

Future<void> _pumpDashboard(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: DashboardContent(context: _dashboardContext)),
    ),
  );
  await tester.pump();
}
