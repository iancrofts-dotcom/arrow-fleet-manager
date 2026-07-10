import '../models/vehicle.dart';
import '../models/vehicle_filter.dart';

class VehicleFilterService {
  const VehicleFilterService();

  List<Vehicle> filterVehicles({
    required List<Vehicle> vehicles,
    required VehicleFilter filter,
  }) {
    switch (filter) {
      case VehicleFilter.all:
        return vehicles;

      // Vehicle status is not yet implemented.
      // These filters will become active once the
      // Vehicle model gains a status field.
      case VehicleFilter.active:
      case VehicleFilter.workshop:
      case VehicleFilter.retired:
        return vehicles;

      case VehicleFilter.motDue:
        final now = DateTime.now();

        return vehicles.where((vehicle) {
          if (vehicle.motExpiry == null) {
            return false;
          }

          final days =
              vehicle.motExpiry!.difference(now).inDays;

          return days >= 0 && days <= 30;
        }).toList();

      case VehicleFilter.serviceDue:
        final now = DateTime.now();

        return vehicles.where((vehicle) {
          if (vehicle.serviceDue == null) {
            return false;
          }

          final days =
              vehicle.serviceDue!.difference(now).inDays;

          return days >= 0 && days <= 30;
        }).toList();

      case VehicleFilter.overdue:
        final now = DateTime.now();

        return vehicles.where((vehicle) {
          final motExpired =
              vehicle.motExpiry != null &&
              vehicle.motExpiry!.isBefore(now);

          final serviceExpired =
              vehicle.serviceDue != null &&
              vehicle.serviceDue!.isBefore(now);

          return motExpired || serviceExpired;
        }).toList();
    }
  }
}