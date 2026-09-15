import '../backend_client.dart';
import '../resilience/central_cached_read.dart';
import 'backend_vehicle_gateway.dart';

class SupabaseVehicleGateway implements BackendVehicleGateway {
  SupabaseVehicleGateway({CentralCachedRead? cachedRead})
    : _cachedRead = cachedRead ?? CentralCachedRead();

  final CentralCachedRead _cachedRead;
  static const _columns =
      'id, legacy_id, registration, fleet_number, make, model, '
      'manufacture_year, vin, mot_expiry, service_due, taxi_plate_number, '
      'taxi_licensing_authority, taxi_plate_issue_date, taxi_plate_expiry, '
      'mot_type, psv_garage_check_enabled, psv_garage_check_interval_weeks, '
      'psv_garage_check_last_date, psv_garage_check_due, '
      'taxi_safety_check_enabled, taxi_safety_check_interval_weeks, '
      'taxi_safety_check_last_date, taxi_safety_check_due, '
      'is_active, created_at, updated_at';

  @override
  Future<List<Map<String, dynamic>>> listVehicles() => _cachedRead.list(
    cacheKey: 'vehicles:list',
    operation: () async =>
        (await BackendClient.client
                .from('vehicles')
                .select(_columns)
                .order('fleet_number'))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<Map<String, dynamic>?> getVehicle(String id) =>
      _cachedRead.maybeSingle(
        cacheKey: 'vehicles:item:$id',
        operation: () => BackendClient.client
            .from('vehicles')
            .select(_columns)
            .eq('id', id)
            .maybeSingle(),
      );

  @override
  Future<Map<String, dynamic>> insertVehicle(Map<String, dynamic> values) =>
      BackendClient.client
          .from('vehicles')
          .insert(values)
          .select(_columns)
          .single();

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> values,
  ) => BackendClient.client
      .from('vehicles')
      .update(values)
      .eq('id', id)
      .select(_columns)
      .single();
}
