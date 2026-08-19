import 'package:flutter/material.dart';

import '../features/auth/widgets/auth_gate.dart';
import '../features/auth/widgets/protected_screen.dart';
import '../features/auth/screens/user_management_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/documents/screens/document_list_screen.dart';
import '../features/vehicles/screens/vehicle_list_screen.dart';
import '../features/drivers/screens/driver_list_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/workshop/screens/workshop_dashboard_screen.dart';

class AppRouter {
  AppRouter._();

  // Root
  static const String root = '/';

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

  static Map<String, WidgetBuilder> get routes => {
        // Authentication
        root: (_) => const AuthGate(),

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
        reports: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewReports,
          child: const ReportsScreen(),
        ),
        documents: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canViewVehicles,
          child: const DocumentListScreen(),
        ),
        users: (_) => ProtectedScreen(
          allow: (permissions) => permissions.canManageUsers,
          child: const UserManagementScreen(),
        ),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Coming Soon'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'The route "${settings.name}" has not been implemented yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
