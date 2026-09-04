import 'package:flutter/material.dart';

import '../../features/drivers/screens/driver_list_screen.dart';
import '../../features/auth/services/permission_service.dart';
import '../../features/auth/widgets/protected_screen.dart';
import '../../features/compliance/screens/compliance_centre_screen.dart';
import '../../features/documents/screens/document_list_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/vehicles/models/vehicle_filter.dart';
import '../../features/vehicles/screens/vehicle_list_screen.dart';
import '../../features/workshop/screens/workshop_dashboard_screen.dart';

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
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewVehicles,
          child: const VehicleListScreen(initialFilter: VehicleFilter.all),
        ),
      ),
    );
  }

  static Future<void> openMotDue(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewVehicles,
          child: const VehicleListScreen(initialFilter: VehicleFilter.motDue),
        ),
      ),
    );
  }

  static Future<void> openServiceDue(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewVehicles,
          child: const VehicleListScreen(
            initialFilter: VehicleFilter.serviceDue,
          ),
        ),
      ),
    );
  }

  static Future<void> openOverdue(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewVehicles,
          child: const VehicleListScreen(initialFilter: VehicleFilter.overdue),
        ),
      ),
    );
  }

  static Future<void> openWorkshop(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canAccessWorkshop,
          child: const WorkshopDashboardScreen(),
        ),
      ),
    );
  }

  static Future<void> openDocuments(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewVehicles,
          child: const DocumentListScreen(),
        ),
      ),
    );
  }

  static bool canOpenRoute(String? route) {
    final permissions = PermissionService.instance;

    switch (route) {
      case '/vehicles':
        return permissions.canViewVehicles;
      case '/drivers':
        return permissions.canViewDrivers;
      case '/reports':
        return permissions.canViewReports;
      case '/compliance':
        return permissions.canViewCompliance;
      case '/documents':
        return permissions.canViewVehicles;
      default:
        return false;
    }
  }

  static Future<void> openRoute(BuildContext context, String? route) async {
    if (route == null) {
      return;
    }

    switch (route) {
      case '/vehicles':
        return openFleet(context);

      case '/drivers':
        return openDrivers(context);

      case '/reports':
        return openReports(context);

      case '/compliance':
        return openCompliance(context);

      case '/documents':
        return openDocuments(context);

      default:
        debugPrint('DashboardNavigation: Unknown route: $route');
    }
  }

  // ==========================================================
  // Drivers
  // ==========================================================

  static Future<void> openDrivers(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewDrivers,
          child: const DriverListScreen(),
        ),
      ),
    );
  }

  // ==========================================================
  // Reports
  // ==========================================================

  static Future<void> openReports(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewReports,
          child: const ReportsScreen(),
        ),
      ),
    );
  }

  static Future<void> openCompliance(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewCompliance,
          child: const ComplianceCentreScreen(),
        ),
      ),
    );
  }
}
