import '../features/auth/models/user_role.dart';

class BackendProfile {
  const BackendProfile({
    required this.id,
    required this.username,
    required this.role,
    required this.isActive,
    this.driverLegacyId,
  });

  final String id;
  final String username;
  final UserRole role;
  final bool isActive;
  final int? driverLegacyId;

  factory BackendProfile.fromJson(Map<String, dynamic> json) {
    final role = switch (json['role']) {
      'administrator' => UserRole.admin,
      'manager' => UserRole.manager,
      'workshop' => UserRole.workshop,
      'technician' => UserRole.technician,
      'driver' => UserRole.driver,
      _ => throw StateError('Unsupported backend profile role.'),
    };
    return BackendProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      role: role,
      isActive: json['is_active'] as bool,
      driverLegacyId: json['driver_legacy_id'] as int?,
    );
  }
}
