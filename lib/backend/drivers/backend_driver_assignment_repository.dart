import 'backend_driver_assignment.dart';
import 'backend_driver_assignment_gateway.dart';

class BackendDriverAssignmentRepository {
  const BackendDriverAssignmentRepository(this._gateway);
  final BackendDriverAssignmentGateway _gateway;
  Future<List<BackendDriverAssignment>> listAssignments() async =>
      (await _gateway.listAssignments())
          .map(BackendDriverAssignment.fromJson)
          .toList();

  Future<List<BackendDriverAssignment>> listAssignmentsForDriver(
    String driverId,
  ) async => (await _gateway.listAssignmentsForDriver(
    driverId,
  )).map(BackendDriverAssignment.fromJson).toList();

  Future<List<BackendDriverAssignment>> listAssignmentsForVehicle(
    String vehicleId,
  ) async => (await _gateway.listAssignmentsForVehicle(
    vehicleId,
  )).map(BackendDriverAssignment.fromJson).toList();
  Future<BackendDriverAssignment?> getAssignment(String id) async {
    final row = await _gateway.getAssignment(id);
    return row == null ? null : BackendDriverAssignment.fromJson(row);
  }

  Future<BackendDriverAssignment> insertAssignment(
    BackendDriverAssignmentWrite assignment,
  ) async => BackendDriverAssignment.fromJson(
    await _gateway.insertAssignment(assignment.toInsertJson()),
  );
  Future<BackendDriverAssignment> updateAssignment(
    String id,
    BackendDriverAssignmentWrite assignment,
  ) async => BackendDriverAssignment.fromJson(
    await _gateway.updateAssignment(id, assignment.toUpdateJson()),
  );
}
