import 'package:arrow_fleet_manager/core/navigation/dashboard_navigation.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_alert.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:arrow_fleet_manager/features/dashboard/sections/priority_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const summary = DashboardSummary(
    vehicleCount: 1,
    driverCount: 1,
    activeVehicles: 1,
    activeDrivers: 1,
    assignedDrivers: 0,
    unassignedDrivers: 1,
    assignedVehicles: 0,
    unassignedVehicles: 1,
    maintenanceDue: 2,
    maintenanceOverdue: 1,
    complianceDue: 3,
    complianceExpired: 1,
    recentActivity: [],
    alerts: [],
  );

  test('unsupported dashboard routes are not actionable', () {
    expect(DashboardNavigation.canOpenRoute('/driver-compliance'), isFalse);
    expect(DashboardNavigation.canOpenRoute('/maintenance'), isFalse);
  });

  testWidgets('unsupported priority routes do not expose navigation', (
    tester,
  ) async {
    final alerts = [
      DashboardAlert(
        title: 'Maintenance',
        message: 'Overdue maintenance remains visible.',
        date: DateTime(2026),
        icon: Icons.build,
        severity: DashboardAlertSeverity.critical,
        route: '/maintenance',
      ),
      DashboardAlert(
        title: 'Driver Compliance',
        message: 'Expired compliance remains visible.',
        date: DateTime(2026),
        icon: Icons.verified_user,
        severity: DashboardAlertSeverity.critical,
        route: '/driver-compliance',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrioritySection(summary: summary.copyWith(alerts: alerts)),
        ),
      ),
    );

    final inkWells = tester.widgetList<InkWell>(find.byType(InkWell)).toList();
    expect(inkWells.where((inkWell) => inkWell.onTap != null), isEmpty);
    expect(find.text('Overdue maintenance remains visible.'), findsOneWidget);
    expect(find.text('Expired compliance remains visible.'), findsOneWidget);
  });
}
