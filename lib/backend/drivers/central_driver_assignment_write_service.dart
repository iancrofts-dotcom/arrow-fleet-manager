import 'backend_driver_assignment.dart';
import 'backend_driver_assignment_repository.dart';
import 'supabase_driver_assignment_gateway.dart';

class CentralDriverAssignmentWriteService {
  CentralDriverAssignmentWriteService({
    BackendDriverAssignmentRepository? repository,
  }) : _repository =
           repository ??
           BackendDriverAssignmentRepository(SupabaseDriverAssignmentGateway());

  final BackendDriverAssignmentRepository _repository;

  Future<BackendDriverAssignment> assign({
    required String driverId,
    required String vehicleId,
  }) => _repository.insertAssignment(
    BackendDriverAssignmentWrite(
      driverId: driverId,
      vehicleId: vehicleId,
      assignedFrom: DateTime.now(),
    ),
  );

  Future<BackendDriverAssignment> end(BackendDriverAssignment assignment) =>
      _repository.updateAssignment(
        assignment.id,
        BackendDriverAssignmentWrite(
          driverId: assignment.driverId,
          vehicleId: assignment.vehicleId,
          assignedFrom: assignment.assignedFrom,
          assignedTo: DateTime.now(),
          isActive: false,
        ),
      );
}
