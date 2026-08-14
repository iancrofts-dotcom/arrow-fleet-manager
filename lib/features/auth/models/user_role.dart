enum UserRole {
  admin,
  manager,
  workshop,
  technician,
  driver,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';

      case UserRole.manager:
        return 'Fleet Manager';

      case UserRole.workshop:
        return 'Workshop Manager';

      case UserRole.technician:
        return 'Technician';

      case UserRole.driver:
        return 'Driver';
    }
  }

  String get databaseValue {
    switch (this) {
      case UserRole.admin:
        return 'admin';

      case UserRole.manager:
        return 'manager';

      case UserRole.workshop:
        return 'workshop';

      case UserRole.technician:
        return 'technician';

      case UserRole.driver:
        return 'driver';
    }
  }

  static UserRole fromDatabase(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;

      case 'manager':
        return UserRole.manager;

      case 'workshop':
        return UserRole.workshop;

      case 'technician':
        return UserRole.technician;

      case 'driver':
        return UserRole.driver;

      default:
        return UserRole.driver;
    }
  }
}
