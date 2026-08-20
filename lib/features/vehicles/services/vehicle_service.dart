import '../../../database/database_service.dart';
import '../../../database/vehicle_repository.dart';
import '../models/vehicle.dart';

class VehicleService {
  VehicleService({VehicleRepository? repository})
      : _repository = repository ??
            VehicleRepository(
              databaseService: DatabaseService(),
            );

  final VehicleRepository _repository;

  Future<List<Vehicle>> getVehicles() async {
    return _repository.getVehicles();
  }

  Future<Map<int, Vehicle>> getVehicleMap() async {
    final vehicles = await getVehicles();

    return {
      for (final vehicle in vehicles)
        if (vehicle.id != null) vehicle.id!: vehicle,
    };
  }

  Future<int> getVehicleCount() async {
    return _repository.getVehicleCount();
  }

  Future<Vehicle?> getVehicleById(
    int id,
  ) async {
    return _repository.getVehicleById(id);
  }

  /// Adds a vehicle and returns the saved record,
  /// including the generated database ID.
  Future<Vehicle> addVehicle(
    Vehicle vehicle,
  ) async {
    final insertedId = await _repository.addVehicle(vehicle);
    final savedVehicle = await _repository.getVehicleById(insertedId);
    if (savedVehicle == null) {
      throw StateError('Inserted vehicle $insertedId could not be retrieved.');
    }
    return savedVehicle;
  }

  Future<void> updateVehicle(
    Vehicle vehicle,
  ) async {
    await _repository.updateVehicle(
      vehicle,
    );
  }

  Future<void> deleteVehicle(
    int id,
  ) async {
    await _repository.deleteVehicle(
      id,
    );
  }
}
