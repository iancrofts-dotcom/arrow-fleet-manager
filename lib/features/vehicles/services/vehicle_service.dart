import '../../../database/database_service.dart';
import '../../../database/vehicle_repository.dart';
import '../../drivers/repositories/driver_assignment_repository.dart';
import '../models/vehicle.dart';

class VehicleService {
  VehicleService({
    VehicleRepository? repository,
    DriverAssignmentRepository? assignmentRepository,
  }) : _repository =
           repository ?? VehicleRepository(databaseService: DatabaseService()),
       _assignmentRepository =
           assignmentRepository ?? DriverAssignmentRepository();

  final VehicleRepository _repository;
  final DriverAssignmentRepository _assignmentRepository;

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

  Future<Vehicle?> getVehicleById(int id) async {
    return _repository.getVehicleById(id);
  }

  /// Adds a vehicle and returns the saved record,
  /// including the generated database ID.
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final insertedId = await _repository.addVehicle(vehicle);
    final savedVehicle = await _repository.getVehicleById(insertedId);
    if (savedVehicle == null) {
      throw StateError('Inserted vehicle $insertedId could not be retrieved.');
    }
    return savedVehicle;
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _repository.updateVehicle(vehicle);
  }

  /// Deactivates a vehicle while retaining its operational history.
  Future<void> deactivateVehicle(int id) async {
    final vehicle = await _repository.getVehicleById(id);
    if (vehicle == null) {
      throw StateError('Vehicle $id could not be found.');
    }

    final activeAssignment = await _assignmentRepository
        .getCurrentAssignmentForVehicle(id);
    if (activeAssignment != null) {
      await _assignmentRepository.updateAssignment(
        activeAssignment.copyWith(assignedTo: DateTime.now(), active: false),
      );
    }

    vehicle.active = false;
    await _repository.updateVehicle(vehicle);
  }

  /// Restores a retained vehicle to the active fleet without recreating any
  /// prior Driver assignment.
  Future<void> reactivateVehicle(int id) async {
    final vehicle = await _repository.getVehicleById(id);
    if (vehicle == null) {
      throw StateError('Vehicle $id could not be found.');
    }

    vehicle.active = true;
    await _repository.updateVehicle(vehicle);
  }
}
