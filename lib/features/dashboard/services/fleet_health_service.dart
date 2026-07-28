import '../models/dashboard_summary.dart';
import '../models/fleet_health.dart';

class FleetHealthService {
  const FleetHealthService();

  FleetHealth calculate(DashboardSummary summary) {
    double score = 100;

    // Penalties
    score -= summary.maintenanceOverdue * 8;
    score -= summary.complianceExpired * 10;

    if (score < 0) {
      score = 0;
    }

    FleetHealthStatus status;

    if (score >= 95) {
      status = FleetHealthStatus.excellent;
    } else if (score >= 85) {
      status = FleetHealthStatus.good;
    } else if (score >= 70) {
      status = FleetHealthStatus.fair;
    } else if (score >= 50) {
      status = FleetHealthStatus.poor;
    } else {
      status = FleetHealthStatus.critical;
    }

    final critical =
        summary.maintenanceOverdue +
        summary.complianceExpired;

    final warning =
        summary.maintenanceDue +
        summary.complianceDue;

    final healthy =
        (summary.vehicleCount - critical - warning)
            .clamp(0, summary.vehicleCount);

    return FleetHealth(
      score: score,
      status: status,
      healthyVehicles: healthy,
      warningVehicles: warning,
      criticalVehicles: critical,
    );
  }
}