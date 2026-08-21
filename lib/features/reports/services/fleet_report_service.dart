import '../../dashboard/models/dashboard_summary.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../../dashboard/services/fleet_metrics_service.dart';
import '../../vehicles/services/vehicle_service.dart';

import '../models/fleet_report.dart';

class FleetReportService {
  FleetReportService({
    DashboardService? dashboardService,
    VehicleService? vehicleService,
    FleetMetricsService? fleetMetricsService,
  }) : _dashboardService = dashboardService ?? DashboardService(),
       _vehicleService = vehicleService ?? VehicleService(),
       _fleetMetricsService =
           fleetMetricsService ?? const FleetMetricsService();

  final DashboardService _dashboardService;
  final VehicleService _vehicleService;
  final FleetMetricsService _fleetMetricsService;

  Future<FleetReport> generateReport() async {
    final DashboardSummary summary = await _dashboardService.loadSummary();
    final vehicleMetrics = _fleetMetricsService.calculate(
      await _vehicleService.getVehicles(),
    );

    return FleetReport(
      generatedAt: DateTime.now(),
      vehicles: summary.vehicles,
      activeVehicles: summary.activeVehicles,
      inactiveVehicles: summary.inactiveVehicles,
      inspections: summary.inspections,
      defects: summary.defects,
      motDue: vehicleMetrics.motDue,
      serviceDue: vehicleMetrics.serviceDue,
      overdue: vehicleMetrics.overdue,
      fleetHealth: summary.fleetHealth,
    );
  }
}
