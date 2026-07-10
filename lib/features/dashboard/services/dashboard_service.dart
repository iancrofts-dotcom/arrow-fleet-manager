import '../../../database/database_service.dart';
import '../../../database/inspection_repository.dart';

import '../../inspections/models/inspection.dart';
import '../../vehicles/services/vehicle_service.dart';

import '../models/dashboard_summary.dart';
import 'fleet_metrics_service.dart';

class DashboardService {
  DashboardService();

  final VehicleService _vehicleService = VehicleService();

  final FleetMetricsService _fleetMetricsService =
      const FleetMetricsService();

  final InspectionRepository _inspectionRepository =
      InspectionRepository(
    databaseService: DatabaseService(),
  );

  Future<DashboardSummary> loadSummary() async {
    final vehicles = await _vehicleService.getVehicles();

    final vehicleCount = vehicles.length;

    final inspectionCount =
        await _inspectionRepository.getInspectionCount();

    final defectCount =
        await _inspectionRepository.getOpenDefectCount();

    final recentInspections =
        await _inspectionRepository.getRecentInspections();

    final metrics =
        _fleetMetricsService.calculate(vehicles);

    final fleetHealth = _calculateFleetHealth(
      vehicles: vehicleCount,
      inspections: inspectionCount,
      defects: defectCount,
    );

    return DashboardSummary(
      vehicles: vehicleCount,
      drivers: 0,
      inspections: inspectionCount,
      defects: defectCount,
      fleetHealth: fleetHealth,
      motDue: metrics.motDue,
      serviceDue: metrics.serviceDue,
      overdue: metrics.overdue,
      recentActivity: _buildRecentActivity(
        recentInspections,
      ),
    );
  }

  List<DashboardActivity> _buildRecentActivity(
    List<Inspection> inspections,
  ) {
    return inspections.map((inspection) {
      return DashboardActivity(
        title: "Inspection Completed",
        subtitle: inspection.registration,
        date: inspection.inspectionDate,
      );
    }).toList();
  }

  int _calculateFleetHealth({
    required int vehicles,
    required int inspections,
    required int defects,
  }) {
    int score = 100;

    if (vehicles == 0) {
      score -= 20;
    }

    if (inspections == 0) {
      score -= 10;
    }

    score -= defects * 5;

    if (score < 0) {
      score = 0;
    }

    if (score > 100) {
      score = 100;
    }

    return score;
  }
}