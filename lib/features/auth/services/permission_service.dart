import '../models/user_role.dart';
import 'auth_service.dart';

class PermissionService {
  PermissionService._();

  static final PermissionService instance = PermissionService._();

  UserRole? get _role => AuthService.instance.currentRole;

  // Role checks
  bool get isAdmin => _role == UserRole.admin;

  bool get isManager => _role == UserRole.manager;

  bool get isWorkshop => _role == UserRole.workshop;

  bool get isDriver => _role == UserRole.driver;

  bool get isViewer => _role == UserRole.viewer;

  // Vehicle permissions
  bool get canManageVehicles => isAdmin || isManager;

  bool get canViewVehicles =>
      canManageVehicles || isWorkshop || isDriver || isViewer;

  // Driver permissions
  bool get canManageDrivers => isAdmin || isManager;

  bool get canViewDrivers =>
      canManageDrivers || isWorkshop;

  // User permissions
  bool get canManageUsers => isAdmin;

  // Workshop permissions
  bool get canManageWorkshop =>
      isAdmin || isManager || isWorkshop;

  bool get canViewWorkshop =>
      canManageWorkshop || isViewer;

  // Reports
  bool get canViewReports =>
      isAdmin || isManager || isWorkshop || isViewer;

  // Documents
  bool get canManageDocuments =>
      isAdmin || isManager || isWorkshop;

  bool get canViewDocuments =>
      canManageDocuments || isDriver || isViewer;

  // Settings
  bool get canManageSettings => isAdmin;
}