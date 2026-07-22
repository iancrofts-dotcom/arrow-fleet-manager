import 'package:flutter/material.dart';
import 'dashboard_alert.dart';
import 'dashboard_activity.dart';
import 'dashboard_insight.dart';

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

  // Activity

  final List<DashboardActivity> recentActivity;
  final List<DashboardAlert> alerts;

  // Legacy compatibility

  int get vehicles => vehicleCount;

  int get drivers => driverCount;

  int get inactiveVehicles =>
      vehicleCount - activeVehicles;

  int get inspections => 0;

  int get defects => 0;

  int get motDue => complianceDue;

  int get serviceDue => maintenanceDue;

  int get overdue => maintenanceOverdue;

  int get fleetHealth {
    if (vehicleCount == 0) {
      return 100;
    }

    final issues =
        maintenanceOverdue + complianceExpired;

    final score =
        100 - ((issues / vehicleCount) * 100);

    return score.clamp(0, 100).round();
  }

  List<DashboardInsight> get insights {
    final list = <DashboardInsight>[];

    if (maintenanceOverdue > 0) {
      list.add(
        DashboardInsight(
          icon: Icons.build,
          title: 'Maintenance',
          message:
              '$maintenanceOverdue vehicle(s) have overdue maintenance.',
        ),
      );
    }

    if (complianceExpired > 0) {
      list.add(
        DashboardInsight(
          icon: Icons.warning,
          title: 'Compliance',
          message:
              '$complianceExpired driver(s) have expired compliance.',
        ),
      );
    }

    if (unassignedDrivers > 0) {
      list.add(
        DashboardInsight(
          icon: Icons.person_off,
          title: 'Drivers',
          message:
              '$unassignedDrivers driver(s) are currently unassigned.',
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
    List<DashboardActivity>? recentActivity,
    List<DashboardAlert>? alerts,
  }) {
    return DashboardSummary(
      vehicleCount: vehicleCount ?? this.vehicleCount,
      driverCount: driverCount ?? this.driverCount,
      activeVehicles: activeVehicles ?? this.activeVehicles,
      activeDrivers: activeDrivers ?? this.activeDrivers,
      assignedDrivers: assignedDrivers ?? this.assignedDrivers,
      unassignedDrivers: unassignedDrivers ?? this.unassignedDrivers,
      assignedVehicles: assignedVehicles ?? this.assignedVehicles,
      unassignedVehicles:
          unassignedVehicles ?? this.unassignedVehicles,
      maintenanceDue: maintenanceDue ?? this.maintenanceDue,
      maintenanceOverdue:
          maintenanceOverdue ?? this.maintenanceOverdue,
      complianceDue: complianceDue ?? this.complianceDue,
      complianceExpired:
          complianceExpired ?? this.complianceExpired,
      recentActivity:
          recentActivity ?? this.recentActivity,
      alerts: alerts ?? this.alerts,
    );
  }
}