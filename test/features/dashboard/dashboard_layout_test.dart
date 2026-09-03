import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_context.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/fleet_health.dart';
import 'package:arrow_fleet_manager/features/dashboard/sections/dashboard_kpi_section.dart';
import 'package:arrow_fleet_manager/features/dashboard/sections/workshop_kpi_section.dart';
import 'package:arrow_fleet_manager/features/dashboard/widgets/dashboard_content.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_dashboard_data.dart';
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
  testWidgets('primary KPIs render before Priority Centre', (tester) async {
    await _pumpDashboard(tester, 1280);

    expect(find.byType(DashboardKpiSection), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(DashboardKpiSection)).dy,
      lessThan(tester.getTopLeft(find.text('Priority Centre')).dy),
    );
    expect(find.text('Priority Centre'), findsOneWidget);
  });

  testWidgets('phone dashboard keeps the primary KPIs in a two by two grid', (
    tester,
  ) async {
    await _pumpDashboard(tester, 390);

    expect(find.byKey(const Key('dashboard-greeting')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-fleet-health')), findsOneWidget);
    expect(find.text('Refresh'), findsNothing);
    expect(find.text('Registered drivers'), findsOneWidget);

    final fleet = tester.getTopLeft(
      find.byKey(const Key('dashboard-kpi-fleet')),
    );
    final drivers = tester.getTopLeft(
      find.byKey(const Key('dashboard-kpi-drivers')),
    );
    final compliance = tester.getTopLeft(
      find.byKey(const Key('dashboard-kpi-compliance')),
    );
    final maintenance = tester.getTopLeft(
      find.byKey(const Key('dashboard-kpi-maintenance')),
    );

    expect(fleet.dy, drivers.dy);
    expect(compliance.dy, maintenance.dy);
    expect(compliance.dy, greaterThan(fleet.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop dashboard keeps all four primary KPIs in one row', (
    tester,
  ) async {
    await _pumpDashboard(tester, 1280);

    final cards = [
      find.byKey(const Key('dashboard-kpi-fleet')),
      find.byKey(const Key('dashboard-kpi-drivers')),
      find.byKey(const Key('dashboard-kpi-compliance')),
      find.byKey(const Key('dashboard-kpi-maintenance')),
    ];
    final top = tester.getTopLeft(cards.first).dy;

    for (final card in cards) {
      expect(card, findsOneWidget);
      expect(tester.getTopLeft(card).dy, top);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('retains the approved command-centre sections only', (
    tester,
  ) async {
    final context = DashboardContext(
      summary: _dashboardContext.summary.copyWith(
        workshopDashboard: const WorkshopDashboardData(
          openInspections: 3,
          completedToday: 1,
          criticalFailures: 1,
          repairsRequired: 2,
        ),
      ),
      fleetHealth: _dashboardContext.fleetHealth,
      onRefresh: _refresh,
    );

    await _pumpDashboard(tester, 1280, dashboardContext: context);

    expect(find.byKey(const Key('dashboard-kpi-fleet')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-kpi-drivers')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-kpi-compliance')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-kpi-maintenance')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-fleet-health')), findsOneWidget);
    expect(find.text('Fleet Health'), findsOneWidget);
    expect(find.text('Fleet Vehicles'), findsNothing);
    expect(find.text('Total Fleet Size'), findsNothing);
    expect(find.text('Active drivers'), findsNothing);
    expect(find.text('Fleet Analytics'), findsNothing);
    expect(find.text('Fleet Attention'), findsNothing);
    expect(find.text('Upcoming Compliance'), findsNothing);
    expect(find.text('Dashboard Alerts'), findsNothing);
    expect(find.text('Compliance Due'), findsNothing);
    expect(find.text('Expired'), findsNothing);
    expect(find.text('Service Due'), findsNothing);
    expect(find.text('Overdue Service'), findsNothing);
    expect(find.text('Vehicle Utilisation'), findsNothing);
    expect(find.text('Driver Availability'), findsOneWidget);
    expect(find.text('Priority Centre'), findsOneWidget);
    expect(find.byType(WorkshopKpiSection), findsOneWidget);
    expect(find.text('Fleet Operations'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);

    expect(
      tester.getTopLeft(find.text('Fleet Operations')).dy,
      tester.getTopLeft(find.text('Recent Activity')).dy,
    );
  });

  testWidgets('operations and recent activity stack below desktop width', (
    tester,
  ) async {
    await _pumpDashboard(tester, 700);

    expect(
      tester.getTopLeft(find.text('Fleet Operations')).dy,
      lessThan(tester.getTopLeft(find.text('Recent Activity')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [700.0, 1280.0]) {
    testWidgets('Dashboard renders without overflow at ${width.toInt()}px', (
      tester,
    ) async {
      await _pumpDashboard(tester, width);

      expect(find.byKey(const Key('dashboard-greeting')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-fleet-health')), findsOneWidget);
      expect(find.byType(DashboardKpiSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _refresh() async {}

Future<void> _pumpDashboard(
  WidgetTester tester,
  double width, {
  DashboardContext dashboardContext = _dashboardContext,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: DashboardContent(context: dashboardContext)),
    ),
  );
  await tester.pump();
}
