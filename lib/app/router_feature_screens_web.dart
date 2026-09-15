import 'package:flutter/material.dart';

import '../backend/central_calendar_parity_service.dart';
import '../backend/central_compliance_navigation.dart';
import '../backend/central_compliance_parity_service.dart';
import '../backend/central_dashboard_parity_service.dart';
import '../backend/central_fleet_report_service.dart';
import '../backend/central_reports_centre_service.dart';
import '../backend/resilience/central_resilience_runtime.dart';
import '../features/auth/screens/central/central_user_management_screen.dart'
    as central_users;
import '../features/calendar/screens/calendar_screen.dart' as shared_calendar;
import '../features/compliance/screens/compliance_centre_screen.dart'
    as shared_compliance;
import '../features/dashboard/dashboard_screen.dart' as shared_dashboard;
import '../features/documents/screens/central_document_list_screen.dart'
    as central_documents;
import '../features/reports/screens/reports_screen.dart' as shared_reports;
import '../features/workshop/screens/central_workshop_dashboard_screen.dart'
    as central_workshop;
import '../shared/widgets/central_connection_banner.dart';

export '../features/drivers/screens/driver_list_screen.dart';
export '../features/vehicles/screens/vehicle_list_screen.dart';

/// Compatibility DTO retained for Web platform contract tests.
class CentralDashboardSnapshot {
  const CentralDashboardSnapshot({
    this.vehicleCount,
    this.activeVehicleCount,
    this.driverCount,
    this.activeDriverCount,
    this.activeAssignmentCount,
    this.unassignedActiveVehicleCount,
    this.motOverdueCount,
    this.motDueSoonCount,
    this.serviceOverdueCount,
    this.serviceDueSoonCount,
  });

  final int? vehicleCount;
  final int? activeVehicleCount;
  final int? driverCount;
  final int? activeDriverCount;
  final int? activeAssignmentCount;
  final int? unassignedActiveVehicleCount;
  final int? motOverdueCount;
  final int? motDueSoonCount;
  final int? serviceOverdueCount;
  final int? serviceDueSoonCount;
}

/// Web uses the same role-aware operational Dashboard as Windows/Android.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CentralDashboardParityService();
    return CentralConnectionBoundary(
      child: shared_dashboard.DashboardScreen(
        loadSummary: () =>
            CentralResilienceRuntime.instance.run(service.loadSummary),
        getFleetHealth: service.getFleetHealth,
      ),
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const central_users.CentralUserManagementScreen();
}

/// Shared Calendar UI with central-only data injected through the parity service.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const service = CentralCalendarParityService();
    return CentralConnectionBoundary(
      child: shared_calendar.CalendarScreen(
        loadEvents: () =>
            CentralResilienceRuntime.instance.run(service.loadEvents),
      ),
    );
  }
}

/// Shared Compliance Centre UI with central-only summary/navigation adapters.
class ComplianceCentreScreen extends StatelessWidget {
  const ComplianceCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CentralComplianceParityService();
    return CentralConnectionBoundary(
      child: shared_compliance.ComplianceCentreScreen(
        loadSummary: () =>
            CentralResilienceRuntime.instance.run(service.loadSummary),
        onOpenAttention: CentralComplianceNavigation.openAttention,
      ),
    );
  }
}

class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const central_documents.CentralDocumentListScreen();
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fleetService = CentralFleetReportService();
    final reportsService = CentralReportsCentreService();
    return CentralConnectionBoundary(
      child: shared_reports.ReportsScreen(
        generateReport: () =>
            CentralResilienceRuntime.instance.run(fleetService.generateReport),
        generateDocument: (query) => CentralResilienceRuntime.instance.run(
          () => reportsService.generate(query),
        ),
      ),
    );
  }
}

class WorkshopDashboardScreen extends StatelessWidget {
  const WorkshopDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const central_workshop.CentralWorkshopDashboardScreen();
}
