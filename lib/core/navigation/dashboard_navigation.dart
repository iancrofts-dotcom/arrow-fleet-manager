import 'package:flutter/material.dart';

import '../../features/drivers/screens/driver_list_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/vehicles/models/vehicle_filter.dart';
import '../../features/vehicles/screens/vehicle_list_screen.dart';

/// Central navigation service for the Dashboard.
///
/// All dashboard widgets should navigate through this class
/// instead of directly creating MaterialPageRoutes.
///
/// This keeps navigation consistent across the application
/// and provides a single place to maintain routing.
class DashboardNavigation {
  DashboardNavigation._();

  // ==========================================================
  // Fleet
  // ==========================================================

  static Future<void> openFleet(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VehicleListScreen(
          initialFilter: VehicleFilter.all,
        ),
      ),
    );
  }

  static Future<void> openMotDue(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VehicleListScreen(
          initialFilter: VehicleFilter.motDue,
        ),
      ),
    );
  }

  static Future<void> openServiceDue(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VehicleListScreen(
          initialFilter: VehicleFilter.serviceDue,
        ),
      ),
    );
  }

  static Future<void> openOverdue(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VehicleListScreen(
          initialFilter: VehicleFilter.overdue,
        ),
      ),
    );
  }

  static Future<void> openWorkshop(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VehicleListScreen(
          initialFilter: VehicleFilter.workshop,
        ),
      ),
    );
  }

static Future<void> openRoute(
  BuildContext context,
  String? route,
) async {
  if (route == null) {
    return;
  }

  switch (route) {
    case '/vehicles':
      return openFleet(context);

    case '/drivers':
      return openDrivers(context);

    case '/maintenance':
      return openServiceDue(context);

    case '/reports':
      return openReports(context);

    default:
      debugPrint(
        'DashboardNavigation: Unknown route: $route',
      );
  }
}

  // ==========================================================
  // Drivers
  // ==========================================================

  static Future<void> openDrivers(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DriverListScreen(),
      ),
    );
  }

  // ==========================================================
  // Reports
  // ==========================================================

  static Future<void> openReports(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReportsScreen(),
      ),
    );
  }
}