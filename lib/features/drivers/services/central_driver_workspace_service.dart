import '../../../backend/drivers/backend_driver_assignment_repository.dart';
import '../../../backend/drivers/supabase_driver_assignment_gateway.dart';
import '../../../backend/vehicles/backend_vehicle_mapper.dart';
import '../../../backend/vehicles/backend_vehicle_repository.dart';
import '../../../backend/vehicles/supabase_vehicle_gateway.dart';
import '../../vehicles/models/vehicle.dart';

/// Read-only central Driver workspace data.
///
/// Assignment mutation remains deliberately unavailable in Supabase mode.
class CentralDriverWorkspaceService {
  CentralDriverWorkspaceService({
    BackendDriverAssignmentRepository? assignments,
    BackendVehicleRepository? vehicles,
  }) : _assignments =
           assignments ??
           BackendDriverAssignmentRepository(SupabaseDriverAssignmentGateway()),
       _vehicles =
           vehicles ?? BackendVehicleRepository(SupabaseVehicleGateway());

  final BackendDriverAssignmentRepository _assignments;
  final BackendVehicleRepository _vehicles;

  Future<Vehicle?> getAssignedVehicle(String driverId) async {
    final rows = await _assignments.listAssignmentsForDriver(driverId);
    final active = rows.where((row) => row.isActive && row.assignedTo == null);
    if (active.isEmpty) return null;

    final assignment = active.first;
    final vehicle = await _vehicles.getVehicle(assignment.vehicleId);
    return vehicle?.toAppVehicle();
  }
}
