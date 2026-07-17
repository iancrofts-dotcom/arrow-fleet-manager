import 'package:flutter/material.dart';

import '../../drivers/services/driver_assignment_service.dart';
import '../../drivers/services/driver_compliance_service.dart';
import '../../drivers/services/driver_service.dart';
import '../../maintenance/services/maintenance_service.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/dashboard_alert.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  DashboardService({
    VehicleService? vehicleService,
    DriverService? driverService,
    DriverAssignmentService? assignmentService,
    DriverComplianceService? complianceService,
    MaintenanceService? maintenanceService,
  })  : _vehicleService = vehicleService ?? VehicleService(),
        _driverService = driverService ?? DriverService(),
        _assignmentService =
            assignmentService ?? DriverAssignmentService(),
        _complianceService =
            complianceService ?? DriverComplianceService(),
        _maintenanceService =
            maintenanceService ?? MaintenanceService();

  final VehicleService _vehicleService;
  final DriverService _driverService;
  final DriverAssignmentService _assignmentService;
  final DriverComplianceService _complianceService;
  final MaintenanceService _maintenanceService;

  void _addAlert(
    List<DashboardAlert> alerts, {
    required String title,
    required String message,
    required DateTime date,
    required IconData icon,
    required DashboardAlertSeverity severity,
    String? route,
  }) {
    alerts.add(
      DashboardAlert(
        title: title,
        message: message,
        date: date,
        icon: icon,
        severity: severity,
        route: route,
      ),
    );
  }

  Future<DashboardSummary> loadSummary() async {
    final vehicles = await _vehicleService.getVehicles();

    final drivers = await _driverService.getDrivers();

    final assignments =
        await _assignmentService.getActiveAssignments();

    final compliance = await _complianceService.getAll();

    final maintenance = await _maintenanceService.getAll();

    final vehicleMap =
        await _vehicleService.getVehicleMap();

    final activities = [
      ...await _assignmentService.getRecentActivities(),
      ...await _maintenanceService.getRecentActivities(),
      ...await _complianceService.getRecentActivities(),
    ];

    activities.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    final recentActivity =
        activities.take(10).toList();

    final maintenanceDue =
        _maintenanceService.dueSoon(maintenance).length;

    final maintenanceOverdue =
        _maintenanceService.overdue(maintenance).length;

    final complianceDue =
        _complianceService.expiringSoon(compliance).length;

    final complianceExpired =
        _complianceService.expired(compliance).length;

    final alerts = <DashboardAlert>[];

    // Overdue maintenance
    for (final record
        in _maintenanceService.overdue(maintenance)) {
      final vehicle = vehicleMap[record.vehicleId];

      _addAlert(
        alerts,
        title: 'Maintenance',
        message:
            '${vehicle?.registration ?? "Vehicle"} • ${record.title} is overdue.',
        date: record.dueDate,
        icon: Icons.build,
        severity: DashboardAlertSeverity.critical,
        route: '/maintenance',
      );
    }

    // Maintenance due soon
    for (final record
        in _maintenanceService.dueSoon(maintenance)) {
      final vehicle = vehicleMap[record.vehicleId];

      _addAlert(
        alerts,
        title: 'Maintenance',
        message:
            '${vehicle?.registration ?? "Vehicle"} • ${record.title} is due in ${record.daysRemaining} day(s).',
        date: record.dueDate,
        icon: Icons.build,
        severity: DashboardAlertSeverity.warning,
        route: '/maintenance',
      );
    }

    alerts.sort(
      (a, b) => a.date.compareTo(b.date),
    );

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
      recentActivity: recentActivity,
      alerts: alerts,
    );
  }
}