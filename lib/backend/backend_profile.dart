import '../features/auth/models/user_role.dart';

class BackendProfile {
  const BackendProfile({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
    this.driverLegacyId,
    this.driverId,
    this.customRoleId,
    this.customRoleName,
    this.customPermissions,
  });

  final String id;
  final String username;
  final UserRole role;
  final bool isActive;
  final int? driverLegacyId;
  final String? driverId;
  final String? customRoleId;
  final String? customRoleName;
  final Set<String>? customPermissions;

  factory BackendProfile.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'administrator' => UserRole.admin,
      'manager' => UserRole.manager,
      'workshop' => UserRole.workshop,
      'technician' => UserRole.technician,
      'driver' => UserRole.driver,
      _ => throw StateError('Unsupported backend profile role.'),
    };
    final custom = json['custom_roles'];
    final customMap = custom is Map ? Map<String, dynamic>.from(custom) : null;
    final rawPermissions = customMap?['permissions'];
    return BackendProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      role: role,
      isActive: json['is_active'] as bool,
      driverLegacyId: json['driver_legacy_id'] as int?,
      driverId: json['driver_id'] as String?,
      customRoleId: json['custom_role_id'] as String?,
      customRoleName: customMap?['name'] as String?,
      customPermissions: rawPermissions is List
          ? rawPermissions.whereType<String>().toSet()
          : null,
    );
  }
}
