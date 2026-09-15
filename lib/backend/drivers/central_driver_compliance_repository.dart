import 'backend_driver_compliance.dart';
import 'central_driver_compliance_gateway.dart';

class CentralDriverComplianceRepository {
  const CentralDriverComplianceRepository(this._gateway);

  final CentralDriverComplianceGateway _gateway;

  Future<List<BackendDriverCompliance>> listCompliance() async =>
      (await _gateway.listCompliance())
          .map(BackendDriverCompliance.fromJson)
          .toList(growable: false);

  Future<BackendDriverCompliance?> getCompliance(String driverId) async {
    final row = await _gateway.getCompliance(driverId);
    return row == null ? null : BackendDriverCompliance.fromJson(row);
  }

  Future<BackendDriverCompliance> saveCompliance({
    required String driverId,
    DateTime? licenceExpiry,
    DateTime? cpcExpiry,
    DateTime? medicalExpiry,
    DateTime? dbsExpiry,
    String? taxiLicenceNumber,
    DateTime? taxiLicenceExpiry,
  }) async => BackendDriverCompliance.fromJson(
    await _gateway.saveCompliance(
      driverId: driverId,
      licenceExpiry: licenceExpiry,
      cpcExpiry: cpcExpiry,
      medicalExpiry: medicalExpiry,
      dbsExpiry: dbsExpiry,
      taxiLicenceNumber: taxiLicenceNumber,
      taxiLicenceExpiry: taxiLicenceExpiry,
    ),
  );
}
