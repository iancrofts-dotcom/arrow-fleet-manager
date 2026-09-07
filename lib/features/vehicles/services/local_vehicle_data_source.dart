import '../../../database/vehicle_repository.dart';
import '../models/vehicle.dart';
import '../models/vehicle_identity.dart';
import 'vehicle_data_source.dart';

class LocalVehicleDataSource implements VehicleDataSource {
  const LocalVehicleDataSource(this._repository);

  final VehicleRepository _repository;

  @override
  Future<List<Vehicle>> listVehicles() => _repository.getVehicles();

  @override
  Future<int> getVehicleCount() => _repository.getVehicleCount();

  @override
  Future<Vehicle?> getVehicle(VehicleIdentity identity) =>
      _repository.getVehicleById(identity.requireLocalId('Vehicle lookup'));

  @override
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final insertedId = await _repository.addVehicle(vehicle);
    final saved = await _repository.getVehicleById(insertedId);
    if (saved == null) {
      throw StateError('Inserted vehicle $insertedId could not be retrieved.');
    }
    return saved;
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final identity = vehicle.identity;
    if (identity == null) {
      throw StateError('Persisted vehicle identity is required.');
    }
    identity.requireLocalId('Vehicle update');
    await _repository.updateVehicle(vehicle);
    final saved = await getVehicle(identity);
    if (saved == null) {
      throw StateError('Updated vehicle could not be retrieved.');
    }
    return saved;
  }
}
