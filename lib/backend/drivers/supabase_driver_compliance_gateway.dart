import '../backend_client.dart';
import '../resilience/central_cached_read.dart';
import 'central_driver_compliance_gateway.dart';

class SupabaseDriverComplianceGateway
    implements CentralDriverComplianceGateway {
  const SupabaseDriverComplianceGateway({CentralCachedRead? cachedRead})
    : _cachedReadOverride = cachedRead;

  final CentralCachedRead? _cachedReadOverride;
  CentralCachedRead get _cachedRead =>
      _cachedReadOverride ?? CentralCachedRead();

  static const _columns =
      'driver_id, licence_expiry, cpc_expiry, medical_expiry, dbs_expiry, taxi_licence_number, taxi_licence_expiry, updated_at';

  @override
  Future<List<Map<String, dynamic>>> listCompliance() => _cachedRead.list(
    cacheKey: 'driver_compliance:list',
    operation: () async =>
        (await BackendClient.client.from('driver_compliance').select(_columns))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<Map<String, dynamic>?> getCompliance(String driverId) =>
      _cachedRead.maybeSingle(
        cacheKey: 'driver_compliance:item:$driverId',
        operation: () => BackendClient.client
            .from('driver_compliance')
            .select(_columns)
            .eq('driver_id', driverId)
            .maybeSingle(),
      );

  @override
  Future<Map<String, dynamic>> saveCompliance({
    required String driverId,
    DateTime? licenceExpiry,
    DateTime? cpcExpiry,
    DateTime? medicalExpiry,
    DateTime? dbsExpiry,
    String? taxiLicenceNumber,
    DateTime? taxiLicenceExpiry,
  }) async {
    final result = await BackendClient.client.rpc(
      'fleet_save_driver_compliance',
      params: {
        'p_driver_id': driverId,
        'p_licence_expiry': _date(licenceExpiry),
        'p_cpc_expiry': _date(cpcExpiry),
        'p_medical_expiry': _date(medicalExpiry),
        'p_dbs_expiry': _date(dbsExpiry),
        'p_taxi_licence_number': taxiLicenceNumber?.trim(),
        'p_taxi_licence_expiry': _date(taxiLicenceExpiry),
      },
    );
    if (result is! Map) {
      throw StateError('Driver compliance update returned an invalid result.');
    }
    return Map<String, dynamic>.from(result);
  }
}

String? _date(DateTime? value) => value == null
    ? null
    : '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
