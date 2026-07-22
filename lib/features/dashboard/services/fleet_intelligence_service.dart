import '../models/dashboard_summary.dart';

class FleetIntelligenceService {
  const FleetIntelligenceService();

  double vehicleUtilisation(DashboardSummary summary) {
    if (summary.vehicleCount == 0) return 0;

    return (summary.assignedVehicles / summary.vehicleCount) * 100;
  }

  double driverUtilisation(DashboardSummary summary) {
    if (summary.driverCount == 0) return 0;

    return (summary.assignedDrivers / summary.driverCount) * 100;
  }

  String maintenanceRisk(DashboardSummary summary) {
    if (summary.maintenanceOverdue >= 10) {
      return 'High';
    }

    if (summary.maintenanceOverdue >= 5) {
      return 'Medium';
    }

    return 'Low';
  }

  String complianceStatus(DashboardSummary summary) {
    if (summary.complianceExpired > 0) {
      return 'Action Required';
    }

    if (summary.complianceDue > 0) {
      return 'Upcoming';
    }

    return 'Compliant';
  }

  bool fleetHealthy(DashboardSummary summary) {
    return summary.fleetHealth >= 90;
  }
}