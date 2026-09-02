import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/fleet_health.dart';
import 'package:arrow_fleet_manager/features/dashboard/services/dashboard_kpi_service.dart';
import 'package:arrow_fleet_manager/features/dashboard/services/fleet_health_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _summary = DashboardSummary(
  vehicleCount: 12,
  driverCount: 7,
  activeVehicles: 10,
  activeDrivers: 6,
  assignedDrivers: 4,
  unassignedDrivers: 3,
  assignedVehicles: 4,
  unassignedVehicles: 8,
  maintenanceDue: 2,
  maintenanceOverdue: 1,
  complianceDue: 3,
  complianceExpired: 2,
  vehicleMotDue: 4,
  maintenanceRecordCount: 9,
  compliancePercentage: 83,
  recentActivity: [],
  alerts: [],
);

void main() {
  test('builds primary KPIs from the dashboard summary contract', () {
    final kpis = const DashboardKpiService().fromSummary(_summary);

    expect(kpis.map((kpi) => kpi.value), ['12', '7', '83%', '9']);
    expect(kpis[0].subtitle, 'Registered vehicles');
    expect(kpis[1].subtitle, 'Registered drivers');
    expect(kpis[2].subtitle, 'Fleet compliance');
    expect(kpis[3].subtitle, 'Maintenance records');
  });

  test('fleet health uses the authoritative penalty calculation', () {
    final fleetHealth = const FleetHealthService().calculate(_summary);

    expect(fleetHealth.score, 72);
    expect(fleetHealth.status, FleetHealthStatus.fair);
  });
}
