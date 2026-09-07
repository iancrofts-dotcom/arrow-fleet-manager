import '../backend_client.dart';
import 'backend_vehicle_gateway.dart';

class SupabaseVehicleGateway implements BackendVehicleGateway {
  static const _columns =
      'id, legacy_id, registration, fleet_number, make, model, '
      'manufacture_year, vin, mot_expiry, service_due, taxi_plate_number, '
      'taxi_licensing_authority, taxi_plate_issue_date, taxi_plate_expiry, '
      'is_active, created_at, updated_at';

  @override
  Future<List<Map<String, dynamic>>> listVehicles() async {
    final rows = await BackendClient.client
        .from('vehicles')
        .select(_columns)
        .order('fleet_number');
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> getVehicle(String id) => BackendClient.client
      .from('vehicles')
      .select(_columns)
      .eq('id', id)
      .maybeSingle();

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
