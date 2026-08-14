import '../models/user_role.dart';
import 'auth_service.dart';

class PermissionService {
  PermissionService._();

  static final PermissionService instance =
      PermissionService._();

  UserRole? get _role =>
      AuthService.instance.currentRole;

  bool get isAdmin =>
      _role == UserRole.admin;

  bool get isManager =>
      _role == UserRole.manager;

  bool get isWorkshop =>
      _role == UserRole.workshop;

  bool get isTechnician =>
      _role == UserRole.technician;

  bool get isDriver =>
      _role == UserRole.driver;

  // ---------------------------------------------------------------------------
  // Fleet
  // ---------------------------------------------------------------------------

  bool get canViewVehicles =>
      isAdmin ||
      isManager ||
      isWorkshop;

  bool get canViewDrivers =>
      isAdmin || isManager;

  bool get canManageVehicles =>
      isAdmin || isManager;

  bool get canManageDrivers =>
      isAdmin || isManager;

  /// Driver-only access to the vehicle assigned through driver_assignments.
  bool get canViewAssignedVehicle => isDriver;

  /// Driver-only access to the locked daily walkaround workflow.
  bool get canPerformDailyInspection => isDriver;

  bool get canViewOwnAccount => isDriver;

  bool get canAccessCalendar =>
      isAdmin || isManager || isWorkshop;

  // ---------------------------------------------------------------------------
  // Administration
  // ---------------------------------------------------------------------------

  bool get canManageUsers =>
      isAdmin;

  bool get canEditSettings =>
      isAdmin;

  // ---------------------------------------------------------------------------
  // Workshop
  // ---------------------------------------------------------------------------

  /// Access to the Workshop section.
  ///
  /// Technicians can work within Workshop, but this does not grant
  /// management or inspection sign-off authority.
  bool get canAccessWorkshop =>
      isAdmin ||
      isManager ||
      isWorkshop ||
      isTechnician;

  /// Management authority within Workshop.
  ///
  /// Technician access is intentionally excluded.
  bool get canManageWorkshop =>
      isAdmin ||
      isManager ||
      isWorkshop;

  /// Operational Workshop access, including technician job work.
  bool get canOperateWorkshop =>
      canManageWorkshop || isTechnician;

  /// Authority to sign off a completed workshop inspection.
  ///
  /// Technicians and Drivers cannot sign off inspections.
  bool get canSignOffInspection =>
      isAdmin ||
      isManager ||
      isWorkshop;

  // ---------------------------------------------------------------------------
  // Dashboard / reporting
  // ---------------------------------------------------------------------------

  /// Workshop and fleet KPIs are not available to Drivers or Technicians.
  bool get canViewKpis =>
      isAdmin ||
      isManager ||
      isWorkshop;

  bool get canViewReports =>
      isAdmin ||
      isManager ||
      isWorkshop;
}
