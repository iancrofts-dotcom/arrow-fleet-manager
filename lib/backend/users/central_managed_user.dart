import '../../features/auth/models/user_role.dart';

class CentralManagedUser {
  const CentralManagedUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.isActive,
    this.customRoleId,
    this.customRoleName,
    this.driverId,
    this.createdAt,
    this.lastSignInAt,
  });

  final String id;
  final String email;
  final String username;
  final UserRole role;
  final bool isActive;
  final String? customRoleId;
  final String? customRoleName;
  final String? driverId;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  bool get isDriverLinked => driverId != null;
  bool get usesCustomRole => customRoleId != null;
  String get displayRole => customRoleName?.trim().isNotEmpty == true
      ? customRoleName!.trim()
      : role.displayName;

  factory CentralManagedUser.fromJson(Map<String, dynamic> json) {
    return CentralManagedUser(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      role: _roleFromBackend(json['role'] as String),
      isActive: json['is_active'] as bool? ?? false,
      customRoleId: json['custom_role_id'] as String?,
      customRoleName: json['custom_role_name'] as String?,
      driverId: json['driver_id'] as String?,
      createdAt: _date(json['created_at']),
      lastSignInAt: _date(json['last_sign_in_at']),
    );
  }
}

String centralRoleValue(UserRole role) => switch (role) {
  UserRole.admin => 'administrator',
  UserRole.manager => 'manager',
  UserRole.workshop => 'workshop',
  UserRole.technician => 'technician',
  UserRole.driver => 'driver',
};

UserRole _roleFromBackend(String role) => switch (role) {
  'administrator' => UserRole.admin,
  'manager' => UserRole.manager,
  'workshop' => UserRole.workshop,
  'technician' => UserRole.technician,
  'driver' => UserRole.driver,
  _ => throw StateError('Unsupported central user role: $role'),
};

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
