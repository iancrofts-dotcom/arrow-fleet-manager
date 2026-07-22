import '../models/user_role.dart';
import 'auth_service.dart';

class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  UserRole? get _role => AuthService.instance.currentRole;

  bool get isAdmin => _role == UserRole.admin;

  bool get isDriver => _role == UserRole.driver;

  bool get canManageVehicles => isAdmin;

  bool get canManageDrivers => isAdmin;

  bool get canManageUsers => isAdmin;

  bool get canViewReports => isAdmin || isDriver;

  bool get canEditSettings => isAdmin;
}