import '../../../backend/vehicles/backend_vehicle.dart';
import '../../../backend/vehicles/backend_vehicle_mapper.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../models/vehicle.dart';
import '../models/vehicle_identity.dart';
import 'vehicle_data_source.dart';

class SupabaseVehicleDataSource implements VehicleDataSource {
  const SupabaseVehicleDataSource(this._repository);

  final BackendVehicleRepository _repository;

  @override
  Future<List<Vehicle>> listVehicles() async =>
      (await _repository.listVehicles())
          .map((row) => row.toAppVehicle())
          .toList();

  @override
  Future<int> getVehicleCount() async =>
      (await _repository.listVehicles()).length;

  @override
  Future<Vehicle?> getVehicle(VehicleIdentity identity) async =>
      (await _repository.getVehicle(
        _requireCentralId(identity, 'Vehicle lookup'),
      ))?.toAppVehicle();

  @override
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    if (vehicle.identity != null) {
      throw ArgumentError(
        'A new central vehicle cannot already have an identity.',
      );
    }
    return (await _repository.insertVehicle(_toWrite(vehicle))).toAppVehicle();
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final identity = vehicle.identity;
    if (identity == null) {
      throw StateError('Persisted vehicle identity is required.');
    }
    return (await _repository.updateVehicle(
      _requireCentralId(identity, 'Vehicle update'),
      _toWrite(vehicle),
    )).toAppVehicle();
  }

  String _requireCentralId(VehicleIdentity identity, String operation) {
    final id = identity.centralIdOrNull;
    if (id == null) {
      throw UnsupportedError('$operation requires a central vehicle UUID.');
    }
    return id;
  }

  BackendVehicleWrite _toWrite(Vehicle vehicle) => BackendVehicleWrite(
    registration: vehicle.registration,
    fleetNumber: vehicle.fleetNumber,
    make: vehicle.make,
    model: vehicle.model,
    manufactureYear: vehicle.year == 0 ? null : vehicle.year,
    vin: vehicle.vin,
    motExpiry: vehicle.motExpiry,
    serviceDue: vehicle.serviceDue,
    taxiPlateNumber: vehicle.taxiPlateNumber,
    taxiLicensingAuthority: vehicle.taxiLicensingAuthority,
    taxiPlateIssueDate: vehicle.taxiPlateIssueDate,
    taxiPlateExpiry: vehicle.taxiPlateExpiry,
    isActive: vehicle.active,
  );
}
