import '../models/user.dart';
import '../models/user_role.dart';

class Permissions {
  Permissions._();

  static bool isAdmin(User? user) =>
      user?.role == UserRole.admin;

  static bool isManager(User? user) =>
      user?.role == UserRole.manager;

  static bool isWorkshop(User? user) =>
      user?.role == UserRole.workshop;

  static bool isDriver(User? user) =>
      user?.role == UserRole.driver;

  static bool isViewer(User? user) =>
      user?.role == UserRole.viewer;

  static bool canManageUsers(User? user) =>
      isAdmin(user);

  static bool canManageFleet(User? user) =>
      isAdmin(user) || isManager(user);

  static bool canManageDrivers(User? user) =>
      isAdmin(user) || isManager(user);

  static bool canManageRepairs(User? user) =>
      isAdmin(user) || isWorkshop(user);

  static bool canViewReports(User? user) =>
      !isDriver(user);

  static bool canCreateInspections(User? user) =>
      isAdmin(user) ||
      isDriver(user);

  static bool canEditVehicles(User? user) =>
      isAdmin(user) ||
      isManager(user);

  static bool canDeleteVehicles(User? user) =>
      isAdmin(user);

  static bool canAccessSettings(User? user) =>
      isAdmin(user);
}