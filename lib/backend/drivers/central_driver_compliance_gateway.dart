abstract interface class CentralDriverComplianceGateway {
  Future<Map<String, dynamic>?> getCompliance(String driverId);
  Future<List<Map<String, dynamic>>> listCompliance();

  Future<Map<String, dynamic>> saveCompliance({
    required String driverId,
    DateTime? licenceExpiry,
    DateTime? cpcExpiry,
    DateTime? medicalExpiry,
    DateTime? dbsExpiry,
    String? taxiLicenceNumber,
    DateTime? taxiLicenceExpiry,
  });
}
