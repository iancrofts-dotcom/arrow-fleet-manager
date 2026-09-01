import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_kpi.dart';
import 'package:arrow_fleet_manager/features/dashboard/widgets/dashboard_kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const maintenanceKpi = DashboardKpi(
    title: 'Maintenance',
    value: '12',
    subtitle: 'Maintenance records',
    icon: 'maintenance',
    trend: DashboardKpiTrend.stable,
  );

  testWidgets('interactive KPI preserves its metric and invokes its action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardKpiCard(
            kpi: maintenanceKpi,
            icon: Icons.build,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Maintenance records'), findsOneWidget);

    await tester.tap(find.text('Maintenance'));

    expect(tapped, isTrue);
  });

  testWidgets('KPI without a route or action remains non-interactive', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardKpiCard(kpi: maintenanceKpi, icon: Icons.build),
        ),
      ),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });
}
