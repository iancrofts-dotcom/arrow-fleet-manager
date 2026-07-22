import 'user_role.dart';

class User {
  const User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.driverId,
    this.isActive = true,
  });

  /// Unique identifier
  final String id;

  /// Username used to log in
  final String username;

  /// Password hash
  final String passwordHash;

  /// User role
  final UserRole role;

  /// Linked driver (null for office users)
  final int? driverId;

  /// Whether the account can log in
  final bool isActive;

  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    UserRole? role,
    int? driverId,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      driverId: driverId ?? this.driverId,
      isActive: isActive ?? this.isActive,
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

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
      ),
      driverId: map['driver_id'] as int?,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  @override
  String toString() {
    return 'User('
        'id: $id, '
        'username: $username, '
        'role: ${role.name}, '
        'driverId: $driverId, '
        'isActive: $isActive'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is User &&
        other.id == id &&
        other.username == username &&
        other.passwordHash == passwordHash &&
        other.role == role &&
        other.driverId == driverId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      username,
      passwordHash,
      role,
      driverId,
      isActive,
    );
  }
}