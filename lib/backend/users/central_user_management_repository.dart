import '../../features/auth/models/user_role.dart';
import 'central_custom_role.dart';
import 'central_managed_user.dart';
import 'central_user_management_gateway.dart';

class CentralUserManagementRepository {
  const CentralUserManagementRepository(this._gateway);

  final CentralUserManagementGateway _gateway;

  Future<List<CentralManagedUser>> listUsers() async =>
      (await _gateway.listUsers())
          .map(CentralManagedUser.fromJson)
          .toList(growable: false);

  Future<List<CentralCustomRole>> listCustomRoles() async =>
      (await _gateway.listCustomRoles())
          .map(CentralCustomRole.fromJson)
          .toList(growable: false);

  Future<CentralCustomRole> createCustomRole({
    required String name,
    required String description,
    required Set<String> permissions,
  }) async => CentralCustomRole.fromJson(
    await _gateway.createCustomRole(
      name: name,
      description: description,
      permissions: permissions,
    ),
  );

  Future<CentralCustomRole> updateCustomRole({
    required CentralCustomRole role,
    required String name,
    required String description,
    required Set<String> permissions,
    required bool isActive,
  }) async => CentralCustomRole.fromJson(
    await _gateway.updateCustomRole(
      id: role.id,
      name: name,
      description: description,
      permissions: permissions,
      isActive: isActive,
    ),
  );

  Future<void> deleteCustomRole(String id) => _gateway.deleteCustomRole(id);

  Future<CentralManagedUser> inviteOrAddUser({
    required String email,
    required String username,
    required UserRole role,
    String? customRoleId,
    required bool isActive,
  }) async => CentralManagedUser.fromJson(
    await _gateway.inviteOrAddUser(
      email: email.trim(),
      username: username.trim(),
      role: centralRoleValue(role),
      customRoleId: customRoleId,
      isActive: isActive,
    ),
  );

  Future<CentralManagedUser> updateUser({
    required CentralManagedUser user,
    required String email,
    required String username,
    required UserRole role,
    String? customRoleId,
    required bool isActive,
  }) async => CentralManagedUser.fromJson(
    await _gateway.updateUser(
      id: user.id,
      email: email.trim(),
      username: username.trim(),
      role: centralRoleValue(role),
      customRoleId: customRoleId,
      isActive: isActive,
    ),
  );

  Future<void> removeUserFromOrganisation(String id) =>
      _gateway.removeUserFromOrganisation(id);
}
