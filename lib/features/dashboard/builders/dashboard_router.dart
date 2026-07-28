import 'package:flutter/material.dart';

import '../models/dashboard_context.dart';

import '../sections/role_sections/administrator_dashboard.dart';
import '../sections/role_sections/driver_dashboard.dart';
import '../sections/role_sections/fleet_manager_dashboard.dart';
import '../sections/role_sections/technician_dashboard.dart';
import '../sections/role_sections/workshop_manager_dashboard.dart';

enum DashboardRole {
  administrator,
  fleetManager,
  workshopManager,
  technician,
  driver,
}

class DashboardRouter {
  const DashboardRouter._();

  static Widget build({
    required DashboardRole role,
    required DashboardContext context,
  }) {
    switch (role) {
      case DashboardRole.administrator:
        return AdministratorDashboard(
          context: context,
        );

      case DashboardRole.fleetManager:
        return FleetManagerDashboard(
          context: context,
        );

      case DashboardRole.workshopManager:
        return WorkshopManagerDashboard(
          context: context,
        );

      case DashboardRole.technician:
        return TechnicianDashboard(
          context: context,
        );

      case DashboardRole.driver:
        return DriverDashboard(
          context: context,
        );
    }
  }
}