import '../features/dashboard/services/fleet_health_service.dart';
import '../features/reports/models/fleet_report.dart';
import 'central_dashboard_parity_service.dart';
import 'vehicles/backend_vehicle_repository.dart';
import 'vehicles/supabase_vehicle_gateway.dart';

class CentralFleetReportService {
  CentralFleetReportService({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Future<FleetReport> generateReport() async {
    final dashboard = await CentralDashboardParityService(
      now: _now,
    ).loadSummary();
    final vehicles = await BackendVehicleRepository(
      SupabaseVehicleGateway(),
    ).listVehicles();
    final today = _dateOnly(_now());
    var motDue = 0;
    var serviceDue = 0;
    var overdue = 0;

    for (final vehicle in vehicles.where((item) => item.isActive)) {
      for (final entry in [
        (vehicle.motExpiry, true),
        (vehicle.serviceDue, false),
      ]) {
        final date = entry.$1;
        if (date == null) continue;
        final days = _dateOnly(date).difference(today).inDays;
        if (days < 0) {
          overdue++;
        } else if (days <= 30) {
          if (entry.$2) {
            motDue++;
          } else {
            serviceDue++;
          }
        }
      }
    }

    return FleetReport(
      generatedAt: _now(),
      vehicles: dashboard.vehicleCount,
      activeVehicles: dashboard.activeVehicles,
      inactiveVehicles: dashboard.inactiveVehicles,
      inspections: dashboard.inspections,
      defects: dashboard.defects,
      motDue: motDue,
      serviceDue: serviceDue,
      overdue: overdue,
      fleetHealth: const FleetHealthService()
          .calculate(dashboard)
          .score
          .round(),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
