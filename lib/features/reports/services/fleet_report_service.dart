import '../../dashboard/models/dashboard_summary.dart';
import '../../dashboard/services/dashboard_service.dart';

import '../models/fleet_report.dart';

class FleetReportService {
  FleetReportService();

  final DashboardService _dashboardService =
      DashboardService();

  Future<FleetReport> generateReport() async {
    final DashboardSummary summary =
        await _dashboardService.loadSummary();

    return FleetReport(
      generatedAt: DateTime.now(),
      vehicles: summary.vehicles,
      activeVehicles: summary.activeVehicles,
      inactiveVehicles: summary.inactiveVehicles,
      inspections: summary.inspections,
      defects: summary.defects,
      motDue: summary.motDue,
      serviceDue: summary.serviceDue,
      overdue: summary.overdue,
      fleetHealth: summary.fleetHealth,
    );
  }
}