import 'dart:io';

import 'package:arrow_fleet_manager/app/router_feature_screens_web.dart';
import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/permission_service.dart';
import 'package:arrow_fleet_manager/platform/platform_capabilities.dart';
import 'package:arrow_fleet_manager/platform/platform_runtime_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Web platform capabilities', () {
    const supabaseWeb = PlatformCapabilities(
      isWeb: true,
      backendMode: BackendMode.supabase,
    );
    const localWeb = PlatformCapabilities(
      isWeb: true,
      backendMode: BackendMode.local,
    );

    test('identifies Web and supports only Supabase on Web', () {
      expect(supabaseWeb.isWeb, isTrue);
      expect(supabaseWeb.isCentralWeb, isTrue);
      expect(supabaseWeb.supportsApplicationConfiguration, isTrue);
      expect(localWeb.isCentralWeb, isFalse);
      expect(localWeb.supportsApplicationConfiguration, isFalse);
      expect(localWeb.supportsLocalData, isFalse);
    });

    test('Web runtime never initializes native SQLite or FFI', () {
      expect(PlatformRuntime.supportsLocalData, isFalse);
      expect(PlatformRuntime.initializeLocalDatabase, returnsNormally);
    });

    test('proven central Web routes remain available', () {
      expect(supabaseWeb.routeAvailable('/dashboard'), isTrue);
      expect(supabaseWeb.routeAvailable('/vehicles'), isTrue);
      expect(supabaseWeb.routeAvailable('/drivers'), isTrue);
      expect(supabaseWeb.routeAvailable('/calendar'), isTrue);
      expect(supabaseWeb.routeAvailable('/compliance'), isTrue);
      expect(supabaseWeb.routeAvailable('/workshop'), isTrue);
      expect(supabaseWeb.routeAvailable('/documents'), isTrue);
    });

    test('central User Management and Reports Centre are available on Web', () {
      expect(supabaseWeb.routeAvailable('/users'), isTrue);
      expect(supabaseWeb.routeAvailable('/reports'), isTrue);
    });

    test('native local and Supabase configurations remain compatible', () {
      for (final mode in BackendMode.values) {
        final capabilities = PlatformCapabilities(
          isWeb: false,
          backendMode: mode,
        );
        expect(capabilities.supportsApplicationConfiguration, isTrue);
        expect(
          capabilities.supportsLocalData,
          mode == BackendMode.local,
          reason: mode.name,
        );
        expect(capabilities.routeAvailable('/drivers'), isTrue);
      }
    });
  });

  test('Web User Management resolves to the central implementation', () {
    final source = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(source, contains('class UserManagementScreen'));
    expect(source, contains('central_users.CentralUserManagementScreen'));
    expect(source, isNot(contains('Users is not available on Web yet')));
    expect(source, isNot(contains('User administration remains disabled')));
  });

  test('Web Reports uses the shared Reports Centre with central data', () {
    final source = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(source, contains('shared_reports.ReportsScreen'));
    expect(source, contains('CentralFleetReportService'));
    expect(source, contains('CentralResilienceRuntime.instance.run'));
    expect(
      source,
      isNot(contains('Central reporting is not enabled on Web yet')),
    );
  });

  test('Web Workshop uses only the central Workshop gateway', () {
    final source = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(source, contains('CentralWorkshopDashboardScreen'));
    expect(source, contains('central_workshop_dashboard_screen.dart'));
    expect(
      source,
      isNot(
        contains("features/workshop/screens/workshop_dashboard_screen.dart"),
      ),
    );
    expect(source, isNot(contains('WorkshopRepository')));
  });

  test('Web calendar delegates through the central parity service', () {
    final source = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    expect(source, contains('shared_calendar.CalendarScreen'));
    expect(source, contains('CentralCalendarParityService'));
    expect(source, contains('loadEvents'));
    expect(source, isNot(contains('CalendarService')));
    expect(source, isNot(contains('DocumentService')));
    expect(source, isNot(contains('AppDatabase')));
  });

  test('unsupported Web routes never import native feature screens', () {
    final source = File(
      'lib/app/router_feature_screens_web.dart',
    ).readAsStringSync();

    for (final forbidden in <String>[
      'UserManagementScreen.dart',
      "features/documents/screens/document_list_screen.dart",
      'features/calendar/services/calendar_service.dart',
      'features/compliance/services/compliance_service.dart',
      'AppDatabase',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('AuthGate resolves Dashboard through platform feature screens', () {
    final source = File(
      'lib/features/auth/widgets/auth_gate.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(
        "if (dart.library.js_interop) '../../../app/router_feature_screens_web.dart'",
      ),
    );
    expect(
      source,
      isNot(contains("import '../../dashboard/dashboard_screen.dart';")),
    );
  });

  test('Web Dashboard snapshot supports proven central metrics', () {
    const snapshot = CentralDashboardSnapshot(
      vehicleCount: 12,
      activeVehicleCount: 10,
      driverCount: 8,
      activeDriverCount: 7,
      activeAssignmentCount: 6,
      unassignedActiveVehicleCount: 4,
      motOverdueCount: 2,
      motDueSoonCount: 3,
      serviceOverdueCount: 1,
      serviceDueSoonCount: 5,
    );

    expect(snapshot.vehicleCount, 12);
    expect(snapshot.activeVehicleCount, 10);
    expect(snapshot.driverCount, 8);
    expect(snapshot.activeDriverCount, 7);
    expect(snapshot.activeAssignmentCount, 6);
    expect(snapshot.unassignedActiveVehicleCount, 4);
    expect(snapshot.motOverdueCount, 2);
    expect(snapshot.motDueSoonCount, 3);
    expect(snapshot.serviceOverdueCount, 1);
    expect(snapshot.serviceDueSoonCount, 5);
  });

  test(
    'Web Dashboard delegates central metrics through the parity service',
    () {
      final source = File(
        'lib/app/router_feature_screens_web.dart',
      ).readAsStringSync();

      expect(source, contains('CentralDashboardParityService'));
      expect(source, contains('CentralDashboardParityService'));
      expect(source, contains('shared_dashboard.DashboardScreen'));
      expect(source, isNot(contains('BackendDriverAssignmentRepository')));
      expect(source, isNot(contains('DriverAssignmentService')));
      expect(source, isNot(contains('CentralVehicleComplianceSummary')));
      expect(source, isNot(contains('ComplianceService')));
      expect(source, isNot(contains('VehicleService')));
      expect(source, isNot(contains('AppDatabase')));
    },
  );

  test('native Supabase release routes reuse proven central screens', () {
    final source = File(
      'lib/app/router_feature_screens_native.dart',
    ).readAsStringSync();

    expect(source, contains('BackendMode.supabase'));
    expect(source, contains('CentralDashboardParityService'));
    expect(source, contains('CentralCalendarParityService'));
    expect(source, contains('CentralComplianceParityService'));
    expect(source, contains('central_workshop.CentralWorkshopDashboardScreen'));
    expect(source, contains('central_documents.CentralDocumentListScreen'));
  });

  test('central Fleet permissions remain least privilege', () {
    expect(_permissionsFor(UserRole.admin).canManageVehicles, isTrue);
    expect(_permissionsFor(UserRole.manager).canManageVehicles, isTrue);
    expect(_permissionsFor(UserRole.workshop).canViewVehicles, isTrue);
    expect(_permissionsFor(UserRole.workshop).canManageVehicles, isFalse);
    expect(_permissionsFor(UserRole.driver).canViewVehicles, isFalse);
  });
}

PermissionService _permissionsFor(UserRole role) =>
    PermissionService(authService: _RoleAuthService(role));

class _RoleAuthService extends AuthService {
  _RoleAuthService(this.role) : super(enableSessionWatchdog: false);

  final UserRole role;

  @override
  UserRole? get currentRole => role;
}
