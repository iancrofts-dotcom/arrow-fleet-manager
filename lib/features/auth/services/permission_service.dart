import '../../../backend/users/central_custom_role.dart';
import '../models/user_role.dart';
import 'auth_service.dart';

class PermissionService {
  PermissionService({AuthService? authService})
    : _authService = authService ?? AuthService.instance;

  static final PermissionService instance = PermissionService();
  final AuthService _authService;

  UserRole? get _role => _authService.currentRole;
  Set<String>? get _custom => _authService.currentUser?.customPermissions;

  bool get isAdmin => _role == UserRole.admin && _custom == null;
  bool get isManager => _role == UserRole.manager && _custom == null;
  bool get isWorkshop => _role == UserRole.workshop && _custom == null;
  bool get isTechnician => _role == UserRole.technician && _custom == null;
  bool get isDriver => _role == UserRole.driver;

  bool _allow(String permission, bool builtIn) =>
      _custom == null ? builtIn : _custom!.contains(permission);

  bool get canViewVehicles => _allow(
    FleetPermissionKey.viewVehicles,
    isAdmin || isManager || isWorkshop,
  );
  bool get canViewDrivers =>
      _allow(FleetPermissionKey.viewDrivers, isAdmin || isManager);
  bool get canManageVehicles =>
      _allow(FleetPermissionKey.manageVehicles, isAdmin || isManager);
  bool get canManageDrivers =>
      _allow(FleetPermissionKey.manageDrivers, isAdmin || isManager);
  bool get canViewDriverComplianceDocuments =>
      _allow(FleetPermissionKey.viewCompliance, isAdmin || isManager);
  bool get canManageDriverComplianceDocuments =>
      _allow(FleetPermissionKey.manageCompliance, isAdmin || isManager);
  bool get canViewOwnComplianceDocuments => isDriver;
  bool get canViewAssignedVehicle => isDriver;
  bool get canPerformDailyInspection => isDriver;
  bool get canViewOwnAccount => isDriver;
  bool get canAccessCalendar => _allow(
    FleetPermissionKey.accessCalendar,
    isAdmin || isManager || isWorkshop,
  );

  // Custom roles never acquire organisation administration. These remain
  // built-in Administrator-only security boundaries.
  bool get canManageUsers => isAdmin;
  bool get canEditSettings => isAdmin;

  bool get canAccessWorkshop => _allow(
    FleetPermissionKey.accessWorkshop,
    isAdmin || isManager || isWorkshop || isTechnician,
  );
  bool get canManageWorkshop => _allow(
    FleetPermissionKey.manageWorkshop,
    isAdmin || isManager || isWorkshop,
  );
  bool get canOperateWorkshop => _allow(
    FleetPermissionKey.operateWorkshop,
    canManageWorkshop || isTechnician,
  );
  bool get canSignOffInspection => _allow(
    FleetPermissionKey.signOffInspection,
    isAdmin || isManager || isWorkshop,
  );
  bool get canManageInspectionTemplates =>
      _allow(FleetPermissionKey.manageInspectionTemplates, canManageWorkshop);
  bool get canViewKpis =>
      _allow(FleetPermissionKey.viewKpis, isAdmin || isManager || isWorkshop);
  bool get canViewReports => _allow(
    FleetPermissionKey.viewReports,
    isAdmin || isManager || isWorkshop,
  );
  bool get canViewCompliance =>
      _allow(FleetPermissionKey.viewCompliance, isAdmin || isManager);
}
