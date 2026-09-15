import '../backend_client.dart';
import 'central_driver_management_gateway.dart';

class SupabaseDriverManagementGateway
    implements CentralDriverManagementGateway {
  const SupabaseDriverManagementGateway();

  Future<Map<String, dynamic>> _invoke(
    String operation,
    Map<String, dynamic> values,
  ) async {
    final response = await BackendClient.client.functions.invoke(
      'manage-drivers',
      body: {'operation': operation, ...values},
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      throw CentralDriverManagementException(_message(data));
    }
    if (data is! Map) {
      throw const CentralDriverManagementException(
        'The Driver management service returned an invalid response.',
      );
    }
    if (operation == 'delete') return Map<String, dynamic>.from(data);
    if (data['driver'] is! Map) {
      throw const CentralDriverManagementException(
        'The Driver management service did not return the saved Driver.',
      );
    }
    return Map<String, dynamic>.from(data['driver'] as Map);
  }

  @override
  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> values) =>
      _invoke('create', values);

  @override
  Future<Map<String, dynamic>> updateDriver(
    String id,
    Map<String, dynamic> values,
  ) => _invoke('update', {'id': id, ...values});

  @override
  Future<Map<String, dynamic>> deactivateDriver(String id) =>
      _invoke('deactivate', {'id': id});

  @override
  Future<void> deleteDriver(String id) async {
    await _invoke('delete', {'id': id});
  }

  String _message(Object? data) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Unable to complete the central Driver-management request.';
  }
}

class CentralDriverManagementException implements Exception {
  const CentralDriverManagementException(this.message);
  final String message;

  @override
  String toString() => message;
}
