import '../models/vehicle.dart';
import '../models/vehicle_sort.dart';

class VehicleSortService {
  const VehicleSortService();

  List<Vehicle> sortVehicles({
    required List<Vehicle> vehicles,
    required VehicleSort sort,
  }) {
    final sorted = List<Vehicle>.from(vehicles);

    switch (sort) {
      case VehicleSort.registration:
        sorted.sort(
          (a, b) => a.registration.compareTo(b.registration),
        );
        break;

      case VehicleSort.fleetNumber:
        sorted.sort(
          (a, b) => a.fleetNumber.compareTo(b.fleetNumber),
        );
        break;

      case VehicleSort.make:
        sorted.sort(
          (a, b) => a.make.compareTo(b.make),
        );
        break;

      case VehicleSort.model:
        sorted.sort(
          (a, b) => a.model.compareTo(b.model),
        );
        break;

      case VehicleSort.motExpiry:
        sorted.sort((a, b) {
          final aDate = a.motExpiry ?? DateTime(9999);
          final bDate = b.motExpiry ?? DateTime(9999);

          return aDate.compareTo(bDate);
        });
        break;

      case VehicleSort.serviceDue:
        sorted.sort((a, b) {
          final aDate = a.serviceDue ?? DateTime(9999);
          final bDate = b.serviceDue ?? DateTime(9999);

          return aDate.compareTo(bDate);
        });
        break;
    }

    return sorted;
  }
}