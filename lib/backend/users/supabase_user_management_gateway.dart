import '../backend_client.dart';
import 'central_user_management_gateway.dart';

class SupabaseUserManagementGateway implements CentralUserManagementGateway {
  const SupabaseUserManagementGateway();

  Future<Map<String, dynamic>> _invoke(
    String operation, [
    Map<String, dynamic> values = const {},
  ]) async {
    final response = await BackendClient.client.functions.invoke(
      'manage-users',
      body: {'operation': operation, ...values},
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      throw CentralUserManagementException(_messageFrom(data));
    }
    if (data is! Map) {
      throw const CentralUserManagementException(
        'The user-management service returned an invalid response.',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<List<Map<String, dynamic>>> listUsers() async {
    final data = await _invoke('list');
    final users = data['users'];
    if (users is! List) {
      throw const CentralUserManagementException(
        'The user-management service did not return a user list.',
      );
    }
    return users
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> listCustomRoles() async {
    final data = await _invoke('list_roles');
    final roles = data['roles'];
    if (roles is! List) {
      throw const CentralUserManagementException(
        'The user-management service did not return a custom-role list.',
      );
    }
    return roles
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> createCustomRole({
    required String name,
    required String description,
    required Set<String> permissions,
  }) async => _roleFrom(
    await _invoke('create_role', {
      'name': name,
      'description': description,
      'permissions': permissions.toList(growable: false),
    }),
  );

  @override
  Future<Map<String, dynamic>> updateCustomRole({
    required String id,
    required String name,
    required String description,
    required Set<String> permissions,
    required bool isActive,
  }) async => _roleFrom(
    await _invoke('update_role', {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions.toList(growable: false),
      'is_active': isActive,
    }),
  );

  @override
  Future<void> deleteCustomRole(String id) async {
    await _invoke('delete_role', {'id': id});
  }

  @override
  Future<Map<String, dynamic>> inviteOrAddUser({
    required String email,
    required String username,
    required String role,
    String? customRoleId,
    required bool isActive,
  }) async => _userFrom(
    await _invoke('invite_or_add', {
      'email': email,
      'username': username,
      'role': role,
      'custom_role_id': customRoleId,
      'is_active': isActive,
    }),
  );

  @override
  Future<Map<String, dynamic>> updateUser({
    required String id,
    required String email,
    required String username,
    required String role,
    String? customRoleId,
    required bool isActive,
  }) async => _userFrom(
    await _invoke('update_membership', {
      'id': id,
      'email': email,
      'username': username,
      'role': role,
      'custom_role_id': customRoleId,
      'is_active': isActive,
    }),
  );

  @override
  Future<void> removeUserFromOrganisation(String id) async {
    await _invoke('remove_membership', {'id': id});
  }

  Map<String, dynamic> _userFrom(Map<String, dynamic> data) {
    final user = data['user'];
    if (user is! Map) {
      throw const CentralUserManagementException(
        'The user-management service did not return the saved user.',
      );
    }
    return Map<String, dynamic>.from(user);
  }

  Map<String, dynamic> _roleFrom(Map<String, dynamic> data) {
    final role = data['role'];
    if (role is! Map) {
      throw const CentralUserManagementException(
        'The user-management service did not return the saved custom role.',
      );
    }
    return Map<String, dynamic>.from(role);
  }

  String _messageFrom(Object? data) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Unable to complete the central user-management request.';
  }
}

class CentralUserManagementException implements Exception {
  const CentralUserManagementException(this.message);
  final String message;

  @override
  String toString() => message;
}
