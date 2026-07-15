import 'dashboard_insight.dart';
import 'package:flutter/material.dart';
import 'dashboard_activity.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.vehicleCount,
    required this.driverCount,
    required this.assignedDrivers,
    required this.unassignedDrivers,
    required this.maintenanceDue,
    required this.maintenanceOverdue,
    required this.complianceDue,
    required this.complianceExpired,
  });

  // ===== New Dashboard =====

  final int vehicleCount;
  final int driverCount;

  final int assignedDrivers;
  final int unassignedDrivers;

  final int maintenanceDue;
  final int maintenanceOverdue;

  final int complianceDue;
  final int complianceExpired;

  // ===== Legacy compatibility =====

  int get vehicles => vehicleCount;

  int get drivers => driverCount;

  int get activeVehicles => vehicleCount;

  int get inactiveVehicles => 0;

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

  if (assignedDrivers < driverCount) {
    list.add(
      DashboardInsight(
        icon: Icons.person_off,
        title: 'Drivers',
        message:
            '${driverCount - assignedDrivers} driver(s) are unassigned.',
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

  List<DashboardActivity> get recentActivity => const [];

  DashboardSummary copyWith({
    int? vehicleCount,
    int? driverCount,
    int? assignedDrivers,
    int? unassignedDrivers,
    int? maintenanceDue,
    int? maintenanceOverdue,
    int? complianceDue,
    int? complianceExpired,
  }) {
    return DashboardSummary(
      vehicleCount:
          vehicleCount ?? this.vehicleCount,
      driverCount:
          driverCount ?? this.driverCount,
      assignedDrivers:
          assignedDrivers ??
              this.assignedDrivers,
      unassignedDrivers:
          unassignedDrivers ??
              this.unassignedDrivers,
      maintenanceDue:
          maintenanceDue ??
              this.maintenanceDue,
      maintenanceOverdue:
          maintenanceOverdue ??
              this.maintenanceOverdue,
      complianceDue:
          complianceDue ??
              this.complianceDue,
      complianceExpired:
          complianceExpired ??
              this.complianceExpired,
    );
  }
}
