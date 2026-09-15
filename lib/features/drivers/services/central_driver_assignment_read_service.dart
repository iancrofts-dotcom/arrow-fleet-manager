import '../../../backend/drivers/backend_driver_assignment.dart';
import '../../../backend/drivers/backend_driver_assignment_repository.dart';
import '../../../backend/drivers/supabase_driver_assignment_gateway.dart';
import '../../../backend/vehicles/backend_vehicle.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../models/central_driver_assignment.dart';
import '../models/driver_identity.dart';

class CentralDriverAssignmentReadService {
  factory CentralDriverAssignmentReadService({
    required BackendDriverAssignmentRepository assignmentRepository,
    required BackendVehicleRepository vehicleRepository,
  }) => CentralDriverAssignmentReadService._(
    assignmentRepository,
    vehicleRepository,
  );

  const CentralDriverAssignmentReadService._(
    this._assignmentRepository,
    this._vehicleRepository,
  );

  factory CentralDriverAssignmentReadService.forSupabase() =>
      CentralDriverAssignmentReadService(
        assignmentRepository: BackendDriverAssignmentRepository(
          SupabaseDriverAssignmentGateway(),
        ),
        vehicleRepository: BackendVehicleRepository(SupabaseVehicleGateway()),
      );

  final BackendDriverAssignmentRepository _assignmentRepository;
  final BackendVehicleRepository _vehicleRepository;

  Future<List<CentralDriverAssignment>> getAssignmentsForDriver(
    DriverIdentity identity,
  ) async {
    final driverId = identity.centralIdOrNull;
    if (driverId == null) {
      throw UnsupportedError(
        'Central assignment lookup requires a central Driver UUID.',
      );
    }

    final assignments = await _assignmentRepository.listAssignmentsForDriver(
      driverId,
    );
    if (assignments.isEmpty) {
      return const <CentralDriverAssignment>[];
    }

    final vehicleIds = assignments.map((row) => row.vehicleId).toSet();
    final vehicles = await Future.wait(
      vehicleIds.map(_vehicleRepository.getVehicle),
    );
    final vehiclesById = <String, BackendVehicle>{
      for (final vehicle in vehicles)
        if (vehicle != null) vehicle.id: vehicle,
    };

    return assignments
        .map(
          (assignment) =>
              _toView(assignment, vehiclesById[assignment.vehicleId]),
        )
        .toList(growable: false);
  }

  CentralDriverAssignment _toView(
    BackendDriverAssignment assignment,
    BackendVehicle? vehicle,
  ) => CentralDriverAssignment(
    id: assignment.id,
    driverId: assignment.driverId,
    vehicleId: assignment.vehicleId,
    assignedFrom: assignment.assignedFrom,
    assignedTo: assignment.assignedTo,
    isActive: assignment.isActive,
    vehicleRegistration: vehicle?.registration ?? 'Unknown vehicle',
    vehicleFleetNumber: vehicle?.fleetNumber ?? '',
    vehicleMake: vehicle?.make,
    vehicleModel: vehicle?.model,
  );
}
