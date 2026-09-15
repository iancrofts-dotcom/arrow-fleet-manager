import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.driverId,
    this.isActive = true,
    this.customRoleId,
    this.customRoleName,
    this.customPermissions,
  });

  final String id;
  final String username;
  final String passwordHash;
  final UserRole role;
  final int? driverId;
  final bool isActive;
  final String? customRoleId;
  final String? customRoleName;
  final Set<String>? customPermissions;

  bool get usesCustomRole => customRoleId != null;
  String get displayRole => customRoleName?.trim().isNotEmpty == true
      ? customRoleName!.trim()
      : role.displayName;

  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    UserRole? role,
    int? driverId,
    bool? isActive,
    String? customRoleId,
    String? customRoleName,
    Set<String>? customPermissions,
  }) => User(
    id: id ?? this.id,
    username: username ?? this.username,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    driverId: driverId ?? this.driverId,
    isActive: isActive ?? this.isActive,
    customRoleId: customRoleId ?? this.customRoleId,
    customRoleName: customRoleName ?? this.customRoleName,
    customPermissions: customPermissions ?? this.customPermissions,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'password_hash': passwordHash,
    'role': role.name,
    'driver_id': driverId,
    'is_active': isActive ? 1 : 0,
  };

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'] as String,
    username: map['username'] as String,
    passwordHash: map['password_hash'] as String,
    role: UserRole.values.firstWhere((r) => r.name == map['role']),
    driverId: map['driver_id'] as int?,
    isActive: (map['is_active'] ?? 1) == 1,
  );

  @override
  String toString() =>
      'User(id: $id, username: $username, role: ${role.name}, driverId: $driverId, isActive: $isActive)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          other.id == id &&
          other.username == username &&
          other.passwordHash == passwordHash &&
          other.role == role &&
          other.driverId == driverId &&
          other.isActive == isActive;

  @override
  int get hashCode =>
      Object.hash(id, username, passwordHash, role, driverId, isActive);
}
