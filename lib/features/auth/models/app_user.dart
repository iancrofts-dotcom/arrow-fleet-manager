import 'user_role.dart';

class AppUser {
  final int? id;
  final String username;
  final String passwordHash;
  final String firstName;
  final String lastName;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });

  String get fullName => '$firstName $lastName';

  AppUser copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? firstName,
    String? lastName,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role.databaseValue,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      email: map['email'] as String,
      role: UserRoleExtension.fromDatabase(
        map['role'] as String,
      ),
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
      lastLogin: map['last_login'] != null
          ? DateTime.parse(
              map['last_login'] as String,
            )
          : null,
    );
  }
}