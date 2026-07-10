import '../../vehicles/models/vehicle.dart';

class FleetMetrics {
  final int active;
  final int inactive;
  final int motDue;
  final int serviceDue;
  final int overdue;
  final int totalVehicles;

  const FleetMetrics({
  required this.totalVehicles,
  required this.active,
  required this.inactive,
  required this.motDue,
  required this.serviceDue,
  required this.overdue,
});
}

class FleetMetricsService {
  const FleetMetricsService();

  FleetMetrics calculate(
    List<Vehicle> vehicles,
  ) {
    final now = DateTime.now();

    int active = 0;
    int inactive = 0;
    int motDue = 0;
    int serviceDue = 0;
    int overdue = 0;

    for (final vehicle in vehicles) {
      if (vehicle.active) {
        active++;
      } else {
        inactive++;
      }

      if (vehicle.motExpiry != null) {
        final days =
            vehicle.motExpiry!.difference(now).inDays;

        if (days < 0) {
          overdue++;
        } else if (days <= 30) {
          motDue++;
        }
      }

      if (vehicle.serviceDue != null) {
        final days =
            vehicle.serviceDue!.difference(now).inDays;

        if (days < 0) {
          overdue++;
        } else if (days <= 30) {
          serviceDue++;
        }
      }
    }

    return FleetMetrics(
      active: active,
      inactive: inactive,
      motDue: motDue,
      serviceDue: serviceDue,
      overdue: overdue,
      totalVehicles: vehicles.length,
    );
  }
}