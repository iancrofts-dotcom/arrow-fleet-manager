import '../../drivers/services/driver_assignment_service.dart';
import '../../drivers/services/driver_compliance_service.dart';
import '../../drivers/services/driver_service.dart';
import '../../maintenance/services/maintenance_service.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  DashboardService({
    VehicleService? vehicleService,
    DriverService? driverService,
    DriverAssignmentService? assignmentService,
    DriverComplianceService? complianceService,
    MaintenanceService? maintenanceService,
  })  : _vehicleService =
            vehicleService ?? VehicleService(),
        _driverService =
            driverService ?? DriverService(),
        _assignmentService =
            assignmentService ??
                DriverAssignmentService(),
        _complianceService =
            complianceService ??
                DriverComplianceService(),
        _maintenanceService =
            maintenanceService ??
                MaintenanceService();

  final VehicleService _vehicleService;
  final DriverService _driverService;
  final DriverAssignmentService _assignmentService;
  final DriverComplianceService _complianceService;
  final MaintenanceService _maintenanceService;

  Future<DashboardSummary> loadSummary() async {
    final vehicles =
        await _vehicleService.getVehicles();

    final drivers =
        await _driverService.getDrivers();

    final assignments =
        await _assignmentService
            .getActiveAssignments();

    final compliance =
        await _complianceService.getAll();

    final maintenance =
        await _maintenanceService.getAll();

    final recentActivity =
        await _assignmentService
            .getRecentActivities();

                final maintenanceDue =
        _maintenanceService
            .dueSoon(maintenance)
            .length;

    final maintenanceOverdue =
        _maintenanceService
            .overdue(maintenance)
            .length;

    final complianceDue =
        _complianceService
            .expiringSoon(compliance)
            .length;

    final complianceExpired =
        _complianceService
            .expired(compliance)
            .length;

    return DashboardSummary(
      vehicleCount: vehicles.length,
      driverCount: drivers.length,
      assignedDrivers: assignments.length,
      unassignedDrivers:
          drivers.length - assignments.length,
      maintenanceDue: maintenanceDue,
      maintenanceOverdue: maintenanceOverdue,
      complianceDue: complianceDue,
      complianceExpired: complianceExpired,

      // Uncomment this AFTER DashboardSummary
      // has been updated to support it.
      //
      recentActivity: recentActivity,
    );
  }
}