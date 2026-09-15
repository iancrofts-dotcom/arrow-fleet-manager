abstract interface class BackendDriverGateway {
  Future<List<Map<String, dynamic>>> listDrivers();
  Future<Map<String, dynamic>?> getDriver(String id);
  Future<Map<String, dynamic>> insertDriver(Map<String, dynamic> values);
  Future<Map<String, dynamic>> updateDriver(
    String id,
    Map<String, dynamic> values,
  );
}
