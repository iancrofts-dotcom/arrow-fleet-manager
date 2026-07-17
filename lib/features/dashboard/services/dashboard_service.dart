import 'package:flutter/material.dart';
import '../../documents/services/document_service.dart';
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

    final documents =
    await DocumentService().getAll();

    final vehicleMap =
        await _vehicleService.getVehicleMap();

    final driverMap =
    await _driverService.getDriverMap();    

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

    // Driver compliance alerts
for (final record in compliance) {
  final driver = driverMap[record.driverId];
  final driverName = driver?.fullName ?? 'Unknown driver';

  // Licence
  if (record.licenceExpired) {
    _addAlert(
      alerts,
      title: 'Driver Compliance',
      message: '$driverName • Licence has expired.',
      date: record.licenceExpiry,
      icon: Icons.badge,
      severity: DashboardAlertSeverity.critical,
      route: '/driver-compliance',
    );
  } else if (record.licenceDaysRemaining <= 30) {
    _addAlert(
      alerts,
      title: 'Driver Compliance',
      message:
          '$driverName • Licence expires in ${record.licenceDaysRemaining} day(s).',
      date: record.licenceExpiry,
      icon: Icons.badge,
      severity: DashboardAlertSeverity.warning,
      route: '/driver-compliance',
    );
  }

  // CPC
  if (record.cpcExpired) {
    _addAlert(
      alerts,
      title: 'Driver Compliance',
      message: '$driverName • CPC has expired.',
      date: record.cpcExpiry,
      icon: Icons.school,
      severity: DashboardAlertSeverity.critical,
      route: '/driver-compliance',
    );
  } else if (record.cpcDaysRemaining <= 30) {
    _addAlert(
      alerts,
      title: 'Driver Compliance',
      message:
          '$driverName • CPC expires in ${record.cpcDaysRemaining} day(s).',
      date: record.cpcExpiry,
      icon: Icons.school,
      severity: DashboardAlertSeverity.warning,
      route: '/driver-compliance',
    );
  }

  // Medical
  if (record.medicalExpired) {
    _addAlert(
      alerts,
      title: 'Driver Compliance',
      message: '$driverName • Medical has expired.',
      date: record.medicalExpiry,
      icon: Icons.medical_services,
      severity: DashboardAlertSeverity.critical,
      route: '/driver-compliance',
    );
  } else if (record.medicalDaysRemaining <= 30) {
    _addAlert(
      alerts,
      title: 'Driver Compliance',
      message:
          '$driverName • Medical expires in ${record.medicalDaysRemaining} day(s).',
      date: record.medicalExpiry,
      icon: Icons.medical_services,
      severity: DashboardAlertSeverity.warning,
      route: '/driver-compliance',
    );
  }
}

// Document alerts
for (final document in documents) {
  String owner = 'Fleet';

  if (document.vehicleId != null) {
    owner = vehicleMap[document.vehicleId!]?.registration ??
        'Vehicle';
  } else if (document.driverId != null) {
    owner = driverMap[document.driverId!]?.fullName ??
        'Driver';
  }

  if (document.isExpired) {
    _addAlert(
      alerts,
      title: 'Documents',
      message:
          '$owner • ${document.title} has expired.',
      date: document.expiryDate,
      icon: Icons.description,
      severity: DashboardAlertSeverity.critical,
      route: '/documents',
    );
  } else if (document.isDueSoon) {
    _addAlert(
      alerts,
      title: 'Documents',
      message:
          '$owner • ${document.title} expires in ${document.daysRemaining} day(s).',
      date: document.expiryDate,
      icon: Icons.description,
      severity: DashboardAlertSeverity.warning,
      route: '/documents',
    );
  }
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