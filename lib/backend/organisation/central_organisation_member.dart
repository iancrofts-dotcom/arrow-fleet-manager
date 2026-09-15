class CentralOrganisationMember {
  const CentralOrganisationMember({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    this.customRoleName,
  });

  final String userId;
  final String username;
  final String email;
  final String role;
  final String? customRoleName;
  final bool isActive;

  factory CentralOrganisationMember.fromJson(Map<String, dynamic> json) =>
      CentralOrganisationMember(
        userId: json['user_id'] as String,
        username: (json['username'] as String?)?.trim() ?? '',
        email: (json['email'] as String?)?.trim() ?? '',
        role: (json['role'] as String?)?.trim() ?? '',
        customRoleName: (json['custom_role_name'] as String?)?.trim(),
        isActive: json['is_active'] as bool? ?? true,
      );
}
