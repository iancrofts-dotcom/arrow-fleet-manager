import '../../../backend/drivers/backend_driver.dart';
import '../../../backend/drivers/backend_driver_assignment.dart';
import '../../../backend/drivers/backend_driver_assignment_repository.dart';
import '../../../backend/drivers/backend_driver_repository.dart';
import '../../../backend/drivers/supabase_driver_assignment_gateway.dart';
import '../../../backend/drivers/supabase_driver_gateway.dart';
import '../models/central_vehicle_assignment.dart';
import '../models/vehicle_identity.dart';

class CentralVehicleAssignmentReadService {
  factory CentralVehicleAssignmentReadService({
    required BackendDriverAssignmentRepository assignmentRepository,
    required BackendDriverRepository driverRepository,
  }) => CentralVehicleAssignmentReadService._(
    assignmentRepository,
    driverRepository,
  );

  const CentralVehicleAssignmentReadService._(
    this._assignmentRepository,
    this._driverRepository,
  );

  factory CentralVehicleAssignmentReadService.forSupabase() =>
      CentralVehicleAssignmentReadService(
        assignmentRepository: BackendDriverAssignmentRepository(
          SupabaseDriverAssignmentGateway(),
        ),
        driverRepository: BackendDriverRepository(SupabaseDriverGateway()),
      );

  final BackendDriverAssignmentRepository _assignmentRepository;
  final BackendDriverRepository _driverRepository;

  Future<List<CentralVehicleAssignment>> getAssignmentsForVehicle(
    VehicleIdentity identity,
  ) async {
    final vehicleId = identity.centralIdOrNull;
    if (vehicleId == null) {
      throw UnsupportedError(
        'Central assignment lookup requires a central Vehicle UUID.',
      );
    }

    final assignments = await _assignmentRepository.listAssignmentsForVehicle(
      vehicleId,
    );
    if (assignments.isEmpty) {
      return const <CentralVehicleAssignment>[];
    }

    final driverIds = assignments.map((row) => row.driverId).toSet();
    final drivers = await Future.wait(
      driverIds.map(_driverRepository.getDriver),
    );
    final driversById = <String, BackendDriver>{
      for (final driver in drivers)
        if (driver != null) driver.id: driver,
    };

    return assignments
        .map(
          (assignment) => _toView(assignment, driversById[assignment.driverId]),
        )
        .toList(growable: false);
  }

  CentralVehicleAssignment _toView(
    BackendDriverAssignment assignment,
    BackendDriver? driver,
  ) => CentralVehicleAssignment(
    id: assignment.id,
    driverId: assignment.driverId,
    vehicleId: assignment.vehicleId,
    assignedFrom: assignment.assignedFrom,
    assignedTo: assignment.assignedTo,
    isActive: assignment.isActive,
    driverName: driver == null
        ? 'Unknown driver'
        : '${driver.firstName} ${driver.lastName}'.trim(),
    driverLicenceNumber: driver?.licenceNumber ?? '',
  );
}
