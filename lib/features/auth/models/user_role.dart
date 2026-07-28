enum UserRole {
  admin,
  manager,
  workshop,
  driver,
  viewer,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';

      case UserRole.manager:
        return 'Fleet Manager';

      case UserRole.workshop:
        return 'Workshop';

      case UserRole.driver:
        return 'Driver';

      case UserRole.viewer:
        return 'Viewer';
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

      case UserRole.driver:
        return 'driver';

      case UserRole.viewer:
        return 'viewer';
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

      case 'driver':
        return UserRole.driver;

      case 'viewer':
        return UserRole.viewer;

      default:
        return UserRole.viewer;
    }
  }
}