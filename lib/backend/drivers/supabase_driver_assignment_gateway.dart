import '../backend_client.dart';
import '../resilience/central_cached_read.dart';
import 'backend_driver_assignment_gateway.dart';

class SupabaseDriverAssignmentGateway
    implements BackendDriverAssignmentGateway {
  SupabaseDriverAssignmentGateway({CentralCachedRead? cachedRead})
    : _cachedRead = cachedRead ?? CentralCachedRead();

  final CentralCachedRead _cachedRead;
  static const _columns =
      'id, legacy_id, driver_id, vehicle_id, assigned_from, assigned_to, is_active, created_at, updated_at';
  @override
  Future<List<Map<String, dynamic>>> listAssignments() => _cachedRead.list(
    cacheKey: 'driver_assignments:list',
    operation: () async =>
        (await BackendClient.client
                .from('driver_assignments')
                .select(_columns)
                .order('assigned_from', ascending: false))
            .cast<Map<String, dynamic>>(),
  );
  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForDriver(
    String driverId,
  ) => _cachedRead.list(
    cacheKey: 'driver_assignments:driver:$driverId',
    operation: () async =>
        (await BackendClient.client
                .from('driver_assignments')
                .select(_columns)
                .eq('driver_id', driverId)
                .order('assigned_from', ascending: false))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForVehicle(
    String vehicleId,
  ) => _cachedRead.list(
    cacheKey: 'driver_assignments:vehicle:$vehicleId',
    operation: () async =>
        (await BackendClient.client
                .from('driver_assignments')
                .select(_columns)
                .eq('vehicle_id', vehicleId)
                .order('assigned_from', ascending: false))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<Map<String, dynamic>?> getAssignment(String id) =>
      _cachedRead.maybeSingle(
        cacheKey: 'driver_assignments:item:$id',
        operation: () => BackendClient.client
            .from('driver_assignments')
            .select(_columns)
            .eq('id', id)
            .maybeSingle(),
      );
  @override
  Future<Map<String, dynamic>> insertAssignment(
    Map<String, dynamic> values,
  ) async {
    final row = await BackendClient.client.rpc(
      'fleet_assign_driver',
      params: {
        'p_driver_id': values['driver_id'],
        'p_vehicle_id': values['vehicle_id'],
        'p_assigned_from': values['assigned_from'],
      },
    );
    return Map<String, dynamic>.from(row as Map);
  }

  @override
  Future<Map<String, dynamic>> updateAssignment(
    String id,
    Map<String, dynamic> values,
  ) async {
    final row = await BackendClient.client.rpc(
      'fleet_end_driver_assignment',
      params: {'p_assignment_id': id, 'p_assigned_to': values['assigned_to']},
    );
    return Map<String, dynamic>.from(row as Map);
  }
}
