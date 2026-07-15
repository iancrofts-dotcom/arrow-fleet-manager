import '../../vehicles/models/vehicle.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/driver.dart';
import '../models/driver_vehicle_assignment.dart';
import '../repositories/driver_assignment_repository.dart';
import 'driver_service.dart';

class DriverAssignmentService {
  DriverAssignmentService({
    DriverAssignmentRepository? repository,
    DriverService? driverService,
    VehicleService? vehicleService,
  })  : _repository =
            repository ?? DriverAssignmentRepository(),
        _driverService =
            driverService ?? DriverService(),
        _vehicleService =
            vehicleService ?? VehicleService();

  final DriverAssignmentRepository _repository;
  final DriverService _driverService;
  final VehicleService _vehicleService;

  Future<List<DriverVehicleAssignment>> getAssignments() async {
    return _repository.getAllAssignments();
  }

  Future<List<DriverVehicleAssignment>> getActiveAssignments() async {
    return _repository.getActiveAssignments();
  }

  Future<DriverVehicleAssignment?> getCurrentAssignmentForDriver(
    int driverId,
  ) async {
    return _repository.getCurrentAssignmentForDriver(driverId);
  }

  Future<DriverVehicleAssignment?> getCurrentAssignmentForVehicle(
    int vehicleId,
  ) async {
    return _repository.getCurrentAssignmentForVehicle(vehicleId);
  }

  Future<Driver?> getAssignedDriver(
    int vehicleId,
  ) async {
    final assignment =
        await getCurrentAssignmentForVehicle(vehicleId);

    if (assignment == null) {
      return null;
    }

    return _driverService.getDriverById(
      assignment.driverId,
    );
  }

  /// NEW: Returns the vehicle currently assigned to a driver.
  Future<Vehicle?> getAssignedVehicle(
    int driverId,
  ) async {
    final assignment =
        await getCurrentAssignmentForDriver(driverId);

    if (assignment == null) {
      return null;
    }

    return _vehicleService.getVehicleById(
      assignment.vehicleId,
    );
  }

  /// Main API used by the UI.
  Future<void> assignDriverToVehicle({
    required int vehicleId,
    Driver? driver,
  }) async {
    if (driver == null) {
      return;
    }

    if (driver.id == null) {
      throw Exception(
        'Driver must be saved before it can be assigned.',
      );
    }

    await assignOrUpdate(
      driverId: driver.id!,
      vehicleId: vehicleId,
    );
  }

  Future<void> assignDriver({
    required int driverId,
    required int vehicleId,
  }) async {
    final driverAssignment =
        await getCurrentAssignmentForDriver(driverId);

    if (driverAssignment != null) {
      throw Exception(
        'Driver already has an active assignment.',
      );
    }

    final vehicleAssignment =
        await getCurrentAssignmentForVehicle(vehicleId);

    if (vehicleAssignment != null) {
      throw Exception(
        'Vehicle already has an active assignment.',
      );
    }

    await _repository.insertAssignment(
      DriverVehicleAssignment(
        driverId: driverId,
        vehicleId: vehicleId,
        assignedFrom: DateTime.now(),
        active: true,
      ),
    );
  }

  Future<void> assignOrUpdate({
    required int driverId,
    required int vehicleId,
  }) async {
    final current =
        await getCurrentAssignmentForVehicle(vehicleId);

    if (current != null) {
      await endAssignment(current);
    }

    await assignDriver(
      driverId: driverId,
      vehicleId: vehicleId,
    );
  }

  Future<void> removeAssignment(
    int vehicleId,
  ) async {
    final current =
        await getCurrentAssignmentForVehicle(vehicleId);

    if (current == null) {
      return;
    }

    await endAssignment(current);
  }

  Future<void> endAssignment(
    DriverVehicleAssignment assignment,
  ) async {
    await _repository.updateAssignment(
      assignment.copyWith(
        assignedTo: DateTime.now(),
        active: false,
      ),
    );
  }

  Future<void> deleteAssignment(
    int id,
  ) async {
    await _repository.deleteAssignment(id);
  }
}