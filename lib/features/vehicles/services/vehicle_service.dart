import '../../../database/database_service.dart';
import '../../../database/vehicle_repository.dart';
import '../models/vehicle.dart';

class VehicleService {
  VehicleService()
      : _repository = VehicleRepository(
          databaseService: DatabaseService(),
        );

  final VehicleRepository _repository;

  Future<List<Vehicle>> getVehicles() async {
    return _repository.getVehicles();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _repository.addVehicle(vehicle);
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _repository.updateVehicle(vehicle);
  }

  Future<void> deleteVehicle(int id) async {
    await _repository.deleteVehicle(id);
  }
}