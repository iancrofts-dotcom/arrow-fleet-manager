import 'package:flutter/material.dart';
import 'dashboard_alert.dart';
import 'dashboard_activity.dart';
import 'dashboard_insight.dart';
import '../../workshop/models/workshop_dashboard_data.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.vehicleCount,
    required this.driverCount,
    required this.activeVehicles,
    required this.activeDrivers,
    required this.assignedDrivers,
    required this.unassignedDrivers,
    required this.assignedVehicles,
    required this.unassignedVehicles,
    required this.maintenanceDue,
    required this.maintenanceOverdue,
    required this.complianceDue,
    required this.complianceExpired,
    required this.recentActivity,
    required this.alerts,
    this.vehicleMotDue = 0,
    this.maintenanceRecordCount = 0,
    this.compliancePercentage = 100,
    this.workshopDashboard,
  });

  // Fleet

  final int vehicleCount;
  final int driverCount;

  final int activeVehicles;
  final int activeDrivers;

  final int assignedDrivers;
  final int unassignedDrivers;

  final int assignedVehicles;
  final int unassignedVehicles;

  // Maintenance

  final int maintenanceDue;
  final int maintenanceOverdue;

  // Compliance

  final int complianceDue;
  final int complianceExpired;

  /// Persisted-vehicle MOT expiries within the next 30 days.
  final int vehicleMotDue;

  /// All persisted maintenance records, irrespective of due status.
  final int maintenanceRecordCount;

  /// Completed compliance checks divided by all required checks for active
  /// vehicles and active drivers. An empty set of required checks scores 100.
  final int compliancePercentage;

  // Activity

  final List<DashboardActivity> recentActivity;
  final List<DashboardAlert> alerts;
  final WorkshopDashboardData? workshopDashboard;

  // Legacy compatibility

  int get vehicles => vehicleCount;

  int get drivers => driverCount;

  int get inactiveVehicles => vehicleCount - activeVehicles;

  int get inspections => workshopDashboard?.inspectionTotal ?? 0;

  int get defects => workshopDashboard?.defectTotal ?? 0;

  int get serviceDue => maintenanceDue;

  int get overdue => maintenanceOverdue;

  List<DashboardInsight> get insights {
    final list = <DashboardInsight>[];

    if (maintenanceOverdue > 0) {
      list.add(
        DashboardInsight(
          icon: Icons.build,
          title: 'Maintenance',
          message: '$maintenanceOverdue vehicle(s) have overdue maintenance.',
        ),
      );
    }

    if (complianceExpired > 0) {
      list.add(
        DashboardInsight(
          icon: Icons.warning,
          title: 'Compliance',
          message: '$complianceExpired driver(s) have expired compliance.',
        ),
      );
    }

    if (unassignedDrivers > 0) {
      list.add(
        DashboardInsight(
          icon: Icons.person_off,
          title: 'Drivers',
          message: '$unassignedDrivers driver(s) are currently unassigned.',
        ),
      );
    }

    if (list.isEmpty) {
      list.add(
        const DashboardInsight(
          icon: Icons.check_circle,
          title: 'Fleet Status',
          message: 'Fleet operating normally.',
        ),
      );
    }

    return list;
  }

  DashboardSummary copyWith({
    int? vehicleCount,
    int? driverCount,
    int? activeVehicles,
    int? activeDrivers,
    int? assignedDrivers,
    int? unassignedDrivers,
    int? assignedVehicles,
    int? unassignedVehicles,
    int? maintenanceDue,
    int? maintenanceOverdue,
    int? complianceDue,
    int? complianceExpired,
    int? vehicleMotDue,
    int? maintenanceRecordCount,
    int? compliancePercentage,
    List<DashboardActivity>? recentActivity,
    List<DashboardAlert>? alerts,
    WorkshopDashboardData? workshopDashboard,
  }) {
    return DashboardSummary(
      vehicleCount: vehicleCount ?? this.vehicleCount,
      driverCount: driverCount ?? this.driverCount,
      activeVehicles: activeVehicles ?? this.activeVehicles,
      activeDrivers: activeDrivers ?? this.activeDrivers,
      assignedDrivers: assignedDrivers ?? this.assignedDrivers,
      unassignedDrivers: unassignedDrivers ?? this.unassignedDrivers,
      assignedVehicles: assignedVehicles ?? this.assignedVehicles,
      unassignedVehicles: unassignedVehicles ?? this.unassignedVehicles,
      maintenanceDue: maintenanceDue ?? this.maintenanceDue,
      maintenanceOverdue: maintenanceOverdue ?? this.maintenanceOverdue,
      complianceDue: complianceDue ?? this.complianceDue,
      complianceExpired: complianceExpired ?? this.complianceExpired,
      vehicleMotDue: vehicleMotDue ?? this.vehicleMotDue,
      maintenanceRecordCount:
          maintenanceRecordCount ?? this.maintenanceRecordCount,
      compliancePercentage: compliancePercentage ?? this.compliancePercentage,
      recentActivity: recentActivity ?? this.recentActivity,
      alerts: alerts ?? this.alerts,
      workshopDashboard: workshopDashboard ?? this.workshopDashboard,
    );
  }
}
