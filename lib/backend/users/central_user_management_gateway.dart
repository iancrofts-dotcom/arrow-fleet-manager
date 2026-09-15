abstract interface class CentralUserManagementGateway {
  Future<List<Map<String, dynamic>>> listUsers();
  Future<List<Map<String, dynamic>>> listCustomRoles();

  Future<Map<String, dynamic>> createCustomRole({
    required String name,
    required String description,
    required Set<String> permissions,
  });

  Future<Map<String, dynamic>> updateCustomRole({
    required String id,
    required String name,
    required String description,
    required Set<String> permissions,
    required bool isActive,
  });

  Future<void> deleteCustomRole(String id);

  Future<Map<String, dynamic>> inviteOrAddUser({
    required String email,
    required String username,
    required String role,
    String? customRoleId,
    required bool isActive,
  });

  Future<Map<String, dynamic>> updateUser({
    required String id,
    required String email,
    required String username,
    required String role,
    String? customRoleId,
    required bool isActive,
  });

  Future<void> removeUserFromOrganisation(String id);
}
