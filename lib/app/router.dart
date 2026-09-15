import 'package:flutter/material.dart';

import '../features/auth/widgets/auth_gate.dart';
import '../features/auth/widgets/protected_screen.dart';
import '../features/auth/invitation/invitation_route.dart';
import '../features/auth/screens/set_password_screen.dart';
import '../features/drivers/screens/driver_portal_destination_screen.dart';
import 'router_feature_screens_native.dart'
    if (dart.library.js_interop) 'router_feature_screens_web.dart';

class AppRouter {
  AppRouter._();

  // Root
  static const String root = '/';
  static const String setPassword = InvitationRoute.path;

  // Main application
  static const String dashboard = '/dashboard';
  static const String vehicles = '/vehicles';
  static const String drivers = '/drivers';
  static const String maintenance = '/maintenance';
  static const String reports = '/reports';
  static const String documents = '/documents';
  static const String settings = '/settings';
  static const String users = '/users';
  static const String workshop = '/workshop';
  static const String calendar = '/calendar';
  static const String compliance = '/compliance';

  // Driver self-service portal
  static const String driverVehicle = '/driver/vehicle';
  static const String driverInspection = '/driver/inspection';
  static const String driverCompliance = '/driver/compliance';
  static const String driverDocuments = '/driver/documents';
  static const String driverProfile = '/driver/profile';

  static Map<String, WidgetBuilder> get routes => {
    // Authentication
    root: (_) => const AuthGate(),
    setPassword: (_) => const SetPasswordScreen(),

    // Dashboard
    dashboard: (_) => const DashboardScreen(),

    // Fleet
    vehicles: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canViewVehicles,
      child: const VehicleListScreen(),
    ),

    // Drivers
    drivers: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canViewDrivers,
      child: const DriverListScreen(),
    ),
    // Workshop
    workshop: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canAccessWorkshop,
      child: const WorkshopDashboardScreen(),
    ),
    calendar: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canAccessCalendar,
      child: const CalendarScreen(),
    ),
    compliance: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canViewCompliance,
      child: const ComplianceCentreScreen(),
    ),
    reports: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canViewReports,
      child: const ReportsScreen(),
    ),
    documents: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canViewVehicles,
      child: const DocumentListScreen(),
    ),
    driverVehicle: (_) => const DriverPortalDestinationScreen(
      destination: DriverPortalDestination.vehicle,
    ),
    driverInspection: (_) => const DriverPortalDestinationScreen(
      destination: DriverPortalDestination.inspection,
    ),
    driverCompliance: (_) => const DriverPortalDestinationScreen(
      destination: DriverPortalDestination.compliance,
    ),
    driverDocuments: (_) => const DriverPortalDestinationScreen(
      destination: DriverPortalDestination.documents,
    ),
    driverProfile: (_) => const DriverPortalDestinationScreen(
      destination: DriverPortalDestination.profile,
    ),
    users: (_) => ProtectedScreen(
      allow: (permissions) => permissions.canManageUsers,
      child: const UserManagementScreen(),
    ),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => ProtectedScreen(
        allow: (_) => true,
        child: Scaffold(
          appBar: AppBar(title: const Text('Page unavailable')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'The route "${settings.name}" is not available in this release.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
