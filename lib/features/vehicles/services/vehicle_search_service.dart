import '../models/vehicle.dart';

class VehicleSearchService {
  const VehicleSearchService();

  List<Vehicle> filterVehicles({
    required List<Vehicle> vehicles,
    required String query,
  }) {
    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      return vehicles;
    }

    return vehicles.where((vehicle) {
      return vehicle.registration.toLowerCase().contains(search) ||
          vehicle.fleetNumber.toLowerCase().contains(search) ||
          vehicle.make.toLowerCase().contains(search) ||
          vehicle.model.toLowerCase().contains(search);
    }).toList();
  }
}