abstract interface class BackendDriverAssignmentGateway {
  Future<List<Map<String, dynamic>>> listAssignments();
  Future<List<Map<String, dynamic>>> listAssignmentsForDriver(String driverId);
  Future<List<Map<String, dynamic>>> listAssignmentsForVehicle(
    String vehicleId,
  );
  Future<Map<String, dynamic>?> getAssignment(String id);
  Future<Map<String, dynamic>> insertAssignment(Map<String, dynamic> values);
  Future<Map<String, dynamic>> updateAssignment(
    String id,
    Map<String, dynamic> values,
  );
}
