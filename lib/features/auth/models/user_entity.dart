import 'user.dart';
import 'user_role.dart';

class UserEntity {
  final String id;
  final String username;
  final String passwordHash;
  final UserRole role;
  final int? driverId;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.driverId,
    required this.isActive,
  });

  factory UserEntity.fromMap(
    Map<String, dynamic> map,
  ) {
    return UserEntity(
      id: map['id'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: UserRole.values.firstWhere(
        (role) => role.name == map['role'],
      ),
      driverId: map['driver_id'] as int?,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role.name,
      'driver_id': driverId,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory UserEntity.fromUser(User user) {
    return UserEntity(
      id: user.id,
      username: user.username,
      passwordHash: user.passwordHash,
      role: user.role,
      driverId: user.driverId,
      isActive: user.isActive,
    );
  }

  User toUser() {
    return User(
      id: id,
      username: username,
      passwordHash: passwordHash,
      role: role,
      driverId: driverId,
      isActive: isActive,
    );
  }

  UserEntity copyWith({
    String? id,
    String? username,
    String? passwordHash,
    UserRole? role,
    int? driverId,
    bool? isActive,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      driverId: driverId ?? this.driverId,
      isActive: isActive ?? this.isActive,
    );
  }
}