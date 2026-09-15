abstract interface class CentralDriverManagementGateway {
  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> values);
  Future<Map<String, dynamic>> updateDriver(
    String id,
    Map<String, dynamic> values,
  );
  Future<Map<String, dynamic>> deactivateDriver(String id);
  Future<void> deleteDriver(String id);
}
