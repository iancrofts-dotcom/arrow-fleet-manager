import 'package:flutter/material.dart';

import '../features/auth/services/permission_service.dart';
import '../features/dashboard/models/dashboard_alert.dart';
import '../features/dashboard/models/dashboard_summary.dart';
import '../features/dashboard/models/fleet_health.dart';
import '../features/dashboard/services/fleet_health_service.dart';
import '../features/workshop/models/workshop_dashboard_data.dart';
import 'drivers/backend_driver.dart';
import 'drivers/backend_driver_assignment.dart';
import 'drivers/backend_driver_assignment_repository.dart';
import 'drivers/backend_driver_repository.dart';
import 'drivers/supabase_driver_assignment_gateway.dart';
import 'drivers/supabase_driver_gateway.dart';
import 'vehicles/backend_vehicle.dart';
import 'vehicles/backend_vehicle_repository.dart';
import 'vehicles/supabase_vehicle_gateway.dart';
import 'workshop/backend_workshop_repository.dart';
import 'workshop/central_workshop_summary.dart';
import 'workshop/supabase_workshop_gateway.dart';

class CentralDashboardParityService {
  CentralDashboardParityService({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final FleetHealthService _fleetHealthService = const FleetHealthService();

  FleetHealth getFleetHealth(DashboardSummary summary) =>
      _fleetHealthService.calculate(summary);

  Future<DashboardSummary> loadSummary() async {
    final permissions = PermissionService.instance;
    final vehicles = permissions.canViewVehicles
        ? await BackendVehicleRepository(
            SupabaseVehicleGateway(),
          ).listVehicles()
        : const <BackendVehicle>[];
    final drivers = permissions.canViewDrivers
        ? await BackendDriverRepository(SupabaseDriverGateway()).listDrivers()
        : const <BackendDriver>[];
    final assignments =
        permissions.canViewVehicles && permissions.canViewDrivers
        ? await BackendDriverAssignmentRepository(
            SupabaseDriverAssignmentGateway(),
          ).listAssignments()
        : const <BackendDriverAssignment>[];

    WorkshopDashboardData? workshopDashboard;
    if (permissions.canAccessWorkshop) {
      final repository = BackendWorkshopRepository(SupabaseWorkshopGateway());
      final inspections = await repository.listInspections();
      final repairs = await repository.listRepairJobs();
      final summary = CentralWorkshopSummary.fromData(
        inspections: inspections,
        repairJobs: repairs,
      );
      final today = _dateOnly(_now());
      workshopDashboard = WorkshopDashboardData(
        openInspections: summary.openInspections,
        completedToday: inspections
            .where(
              (item) =>
                  item.dateCompleted != null &&
                  _dateOnly(item.dateCompleted!).isAtSameMomentAs(today),
            )
            .length,
        criticalFailures: summary.criticalFailures,
        repairsRequired: summary.outstandingRepairs,
        inspectionTotal: summary.totalInspections,
        defectTotal: summary.criticalFailures,
        repairsOutstanding: summary.outstandingRepairs,
        awaitingParts: summary.awaitingParts,
        awaitingSignOff: inspections
            .where((item) => item.isCompleted && item.status != 'signedOff')
            .length,
      );
    }

    final activeVehicles = vehicles
        .where((vehicle) => vehicle.isActive)
        .toList();
    final activeDrivers = drivers.where((driver) => driver.isActive).toList();
    final currentAssignments = assignments
        .where((item) => item.isActive)
        .toList();
    final assignedVehicleIds = currentAssignments
        .map((item) => item.vehicleId)
        .toSet();
    final assignedDriverIds = currentAssignments
        .map((item) => item.driverId)
        .toSet();

    final today = _dateOnly(_now());
    var motDue = 0;
    var motOverdue = 0;
    var serviceDue = 0;
    var serviceOverdue = 0;
    final alerts = <DashboardAlert>[];

    for (final vehicle in activeVehicles) {
      _accumulateVehicleDate(
        vehicle: vehicle,
        date: vehicle.motExpiry,
        label: 'MOT',
        today: today,
        onDueSoon: () => motDue++,
        onOverdue: () => motOverdue++,
        alerts: alerts,
      );
      _accumulateVehicleDate(
        vehicle: vehicle,
        date: vehicle.serviceDue,
        label: 'Service',
        today: today,
        onDueSoon: () => serviceDue++,
        onOverdue: () => serviceOverdue++,
        alerts: alerts,
      );
    }

    alerts.sort((a, b) {
      final severity = b.severity.index.compareTo(a.severity.index);
      if (severity != 0) return severity;
      return a.date.compareTo(b.date);
    });

    final requiredChecks = activeVehicles.length * 2;
    final recordedValidChecks = activeVehicles.fold<int>(0, (total, vehicle) {
      var valid = 0;
      for (final date in [vehicle.motExpiry, vehicle.serviceDue]) {
        if (date != null && !_dateOnly(date).isBefore(today)) valid++;
      }
      return total + valid;
    });
    final compliancePercentage = requiredChecks == 0
        ? 100
        : ((recordedValidChecks / requiredChecks) * 100).round();

    return DashboardSummary(
      vehicleCount: vehicles.length,
      driverCount: drivers.length,
      activeVehicles: activeVehicles.length,
      activeDrivers: activeDrivers.length,
      assignedDrivers: activeDrivers
          .where((driver) => assignedDriverIds.contains(driver.id))
          .length,
      unassignedDrivers: activeDrivers
          .where((driver) => !assignedDriverIds.contains(driver.id))
          .length,
      assignedVehicles: activeVehicles
          .where((vehicle) => assignedVehicleIds.contains(vehicle.id))
          .length,
      unassignedVehicles: activeVehicles
          .where((vehicle) => !assignedVehicleIds.contains(vehicle.id))
          .length,
      maintenanceDue: serviceDue,
      maintenanceOverdue: serviceOverdue,
      complianceDue: motDue,
      complianceExpired: motOverdue,
      vehicleMotDue: motDue,
      maintenanceRecordCount: activeVehicles
          .where((vehicle) => vehicle.serviceDue != null)
          .length,
      compliancePercentage: compliancePercentage,
      recentActivity: const [],
      alerts: alerts.take(15).toList(growable: false),
      workshopDashboard: workshopDashboard,
    );
  }

  void _accumulateVehicleDate({
    required BackendVehicle vehicle,
    required DateTime? date,
    required String label,
    required DateTime today,
    required VoidCallback onDueSoon,
    required VoidCallback onOverdue,
    required List<DashboardAlert> alerts,
  }) {
    if (date == null) return;
    final day = _dateOnly(date);
    final days = day.difference(today).inDays;
    if (days < 0) {
      onOverdue();
      alerts.add(
        DashboardAlert(
          title: '$label overdue',
          message:
              '${vehicle.registration} • $label expired ${-days} day(s) ago.',
          date: day,
          icon: Icons.warning_amber_outlined,
          severity: DashboardAlertSeverity.critical,
          route: '/compliance',
        ),
      );
      return;
    }
    if (days <= 30) {
      onDueSoon();
      alerts.add(
        DashboardAlert(
          title: '$label due',
          message: '${vehicle.registration} • $label due in $days day(s).',
          date: day,
          icon: label == 'MOT' ? Icons.event_outlined : Icons.build_outlined,
          severity: DashboardAlertSeverity.warning,
          route: '/compliance',
        ),
      );
    }
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
