import '../../../database/database_service.dart';
import '../../../database/vehicle_repository.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../../../config/backend_mode.dart';
import '../../drivers/repositories/driver_assignment_repository.dart';
import '../models/vehicle.dart';
import '../models/vehicle_identity.dart';
import 'local_vehicle_data_source.dart';
import 'supabase_vehicle_data_source.dart';
import 'vehicle_data_source.dart';

class VehicleService {
  VehicleService({
    VehicleRepository? repository,
    DriverAssignmentRepository? assignmentRepository,
    VehicleDataSource? dataSource,
  }) : _dataSource =
           dataSource ??
           LocalVehicleDataSource(
             repository ??
                 VehicleRepository(databaseService: DatabaseService()),
           ),
       _assignmentRepository =
           assignmentRepository ?? DriverAssignmentRepository();

  factory VehicleService.forConfiguredBackend() =>
      VehicleService.forMode(BackendModeConfig.current);

  factory VehicleService.forMode(
    BackendMode mode, {
    VehicleRepository? localRepository,
    BackendVehicleRepository? backendRepository,
  }) => switch (mode) {
    BackendMode.local => VehicleService(repository: localRepository),
    BackendMode.supabase => VehicleService(
      dataSource: SupabaseVehicleDataSource(
        backendRepository ?? BackendVehicleRepository(SupabaseVehicleGateway()),
      ),
    ),
  };

  final VehicleDataSource _dataSource;
  final DriverAssignmentRepository _assignmentRepository;

  Future<List<Vehicle>> getVehicles() async {
    return _dataSource.listVehicles();
  }

  Future<Map<int, Vehicle>> getVehicleMap() async {
    final vehicles = await getVehicles();

    return {
      for (final vehicle in vehicles)
        if (vehicle.id != null) vehicle.id!: vehicle,
    };
  }

  Future<int> getVehicleCount() async {
    return _dataSource.getVehicleCount();
  }

  Future<Vehicle?> getVehicleById(int id) async {
    return _dataSource.getVehicle(VehicleIdentity.local(id));
  }

  Future<Vehicle?> getVehicle(VehicleIdentity identity) {
    return _dataSource.getVehicle(identity);
  }

  /// Adds a vehicle and returns the saved record,
  /// including the generated database ID.
  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    return _dataSource.addVehicle(vehicle);
  }

  Future<Vehicle> updateVehicle(Vehicle vehicle) {
    return _dataSource.updateVehicle(vehicle);
  }

  /// Deactivates a vehicle while retaining its operational history.
  Future<void> deactivateVehicle(int id) async {
    await deactivateVehicleByIdentity(VehicleIdentity.local(id));
  }

  Future<Vehicle> deactivateVehicleByIdentity(VehicleIdentity identity) async {
    final vehicle = await _dataSource.getVehicle(identity);
    if (vehicle == null) {
      throw StateError('Vehicle could not be found.');
    }

    if (identity.localIdOrNull case final localId?) {
      final activeAssignment = await _assignmentRepository
          .getCurrentAssignmentForVehicle(localId);
      if (activeAssignment != null) {
        await _assignmentRepository.updateAssignment(
          activeAssignment.copyWith(assignedTo: DateTime.now(), active: false),
        );
      }
    }

    vehicle.active = false;
    return _dataSource.updateVehicle(vehicle);
  }

  /// Restores a retained vehicle to the active fleet without recreating any
  /// prior Driver assignment.
  Future<void> reactivateVehicle(int id) async {
    await reactivateVehicleByIdentity(VehicleIdentity.local(id));
  }

  Future<Vehicle> reactivateVehicleByIdentity(VehicleIdentity identity) async {
    final vehicle = await _dataSource.getVehicle(identity);
    if (vehicle == null) {
      throw StateError('Vehicle could not be found.');
    }

    vehicle.active = true;
    return _dataSource.updateVehicle(vehicle);
  }
}
