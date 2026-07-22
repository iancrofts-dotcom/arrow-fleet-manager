enum UserRole {
  admin,
  manager,
  driver,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';

      case UserRole.manager:
        return 'Fleet Manager';

      case UserRole.driver:
        return 'Driver';
    }
  }
}