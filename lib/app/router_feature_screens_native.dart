import 'package:flutter/material.dart';

import '../config/backend_mode.dart';
import '../backend/central_dashboard_parity_service.dart';
import '../backend/central_calendar_parity_service.dart';
import '../backend/central_fleet_report_service.dart';
import '../backend/central_reports_centre_service.dart';
import '../backend/resilience/central_resilience_runtime.dart';
import '../backend/central_compliance_parity_service.dart';
import '../backend/central_compliance_navigation.dart';
import '../features/calendar/screens/calendar_screen.dart' as local_calendar;
import '../features/compliance/screens/compliance_centre_screen.dart'
    as local_compliance;
import '../features/dashboard/dashboard_screen.dart' as local_dashboard;
import '../features/auth/screens/user_management_screen.dart' as local_users;
import '../features/auth/screens/central/central_user_management_screen.dart'
    as central_users;
import '../features/documents/screens/document_list_screen.dart'
    as local_documents;
import '../features/documents/screens/central_document_list_screen.dart'
    as central_documents;
import '../features/reports/screens/reports_screen.dart' as local_reports;
import '../features/workshop/screens/workshop_dashboard_screen.dart'
    as local_workshop;
import '../features/workshop/screens/central_workshop_dashboard_screen.dart'
    as central_workshop;

export '../features/drivers/screens/driver_list_screen.dart';
export '../features/vehicles/screens/vehicle_list_screen.dart';

/// Keeps native local mode on the established SQLite dashboard while ensuring
/// Windows/Android Supabase mode uses the same proven central dashboard as Web.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.backendMode});

  final BackendMode? backendMode;

  @override
  Widget build(BuildContext context) =>
      (backendMode ?? BackendModeConfig.current) == BackendMode.supabase
      ? local_dashboard.DashboardScreen(
          loadSummary: CentralDashboardParityService().loadSummary,
          getFleetHealth: CentralDashboardParityService().getFleetHealth,
        )
      : const local_dashboard.DashboardScreen();
}

/// Central mode must never fall back to the local calendar services.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key, this.backendMode});

  final BackendMode? backendMode;

  @override
  Widget build(BuildContext context) =>
      (backendMode ?? BackendModeConfig.current) == BackendMode.supabase
      ? local_calendar.CalendarScreen(
          loadEvents: CentralCalendarParityService().loadEvents,
        )
      : const local_calendar.CalendarScreen();
}

/// Central mode must never show compliance calculated from the local database.
class ComplianceCentreScreen extends StatelessWidget {
  const ComplianceCentreScreen({super.key, this.backendMode});

  final BackendMode? backendMode;

  @override
  Widget build(BuildContext context) =>
      (backendMode ?? BackendModeConfig.current) == BackendMode.supabase
      ? local_compliance.ComplianceCentreScreen(
          loadSummary: CentralComplianceParityService().loadSummary,
          onOpenAttention: CentralComplianceNavigation.openAttention,
        )
      : const local_compliance.ComplianceCentreScreen();
}

/// Features below this boundary have not yet been migrated to the central
/// schema. Supabase mode must not silently open their SQLite implementations.
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key, this.backendMode});

  final BackendMode? backendMode;

  @override
  Widget build(BuildContext context) =>
      (backendMode ?? BackendModeConfig.current) == BackendMode.supabase
      ? const central_users.CentralUserManagementScreen()
      : const local_users.UserManagementScreen();
}

class WorkshopDashboardScreen extends StatelessWidget {
  const WorkshopDashboardScreen({super.key, this.backendMode});

  final BackendMode? backendMode;

  @override
  Widget build(BuildContext context) =>
      (backendMode ?? BackendModeConfig.current) == BackendMode.supabase
      ? const central_workshop.CentralWorkshopDashboardScreen()
      : const local_workshop.WorkshopDashboardScreen();
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, this.backendMode});

  final BackendMode? backendMode;

  @override
  Widget build(BuildContext context) =>
      (backendMode ?? BackendModeConfig.current) == BackendMode.supabase
      ? local_reports.ReportsScreen(
          generateReport: () => CentralResilienceRuntime.instance.run(
            CentralFleetReportService().generateReport,
          ),
          generateDocument: (query) => CentralResilienceRuntime.instance.run(
            () => CentralReportsCentreService().generate(query),
          ),
        )
      : const local_reports.ReportsScreen();
}

class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key, this.backendMode});

  final BackendMode? backendMode;

  @override
  Widget build(BuildContext context) =>
      (backendMode ?? BackendModeConfig.current) == BackendMode.supabase
      ? const central_documents.CentralDocumentListScreen()
      : const local_documents.DocumentListScreen();
}
