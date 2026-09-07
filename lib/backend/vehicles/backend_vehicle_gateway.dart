abstract interface class BackendVehicleGateway {
  Future<List<Map<String, dynamic>>> listVehicles();
  Future<Map<String, dynamic>?> getVehicle(String id);
  Future<Map<String, dynamic>> insertVehicle(Map<String, dynamic> values);
  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> values,
  );
}
