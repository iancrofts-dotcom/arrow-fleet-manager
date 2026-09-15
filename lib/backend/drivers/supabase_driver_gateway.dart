import '../backend_client.dart';
import '../resilience/central_cached_read.dart';
import 'backend_driver_gateway.dart';

class SupabaseDriverGateway implements BackendDriverGateway {
  SupabaseDriverGateway({CentralCachedRead? cachedRead})
    : _cachedRead = cachedRead ?? CentralCachedRead();

  final CentralCachedRead _cachedRead;
  static const _columns =
      'id, legacy_id, first_name, last_name, licence_number, licence_expiry, phone, email, username, is_active, created_at, updated_at';
  @override
  Future<List<Map<String, dynamic>>> listDrivers() => _cachedRead.list(
    cacheKey: 'drivers:list',
    operation: () async =>
        (await BackendClient.client
                .from('drivers')
                .select(_columns)
                .isFilter('deleted_at', null)
                .order('last_name'))
            .cast<Map<String, dynamic>>(),
  );
  @override
  Future<Map<String, dynamic>?> getDriver(String id) => _cachedRead.maybeSingle(
    cacheKey: 'drivers:item:$id',
    operation: () => BackendClient.client
        .from('drivers')
        .select(_columns)
        .eq('id', id)
        .maybeSingle(),
  );
  @override
  Future<Map<String, dynamic>> insertDriver(Map<String, dynamic> values) =>
      BackendClient.client
          .from('drivers')
          .insert(values)
          .select(_columns)
          .single();
  @override
  Future<Map<String, dynamic>> updateDriver(
    String id,
    Map<String, dynamic> values,
  ) => BackendClient.client
      .from('drivers')
      .update(values)
      .eq('id', id)
      .select(_columns)
      .single();
}
