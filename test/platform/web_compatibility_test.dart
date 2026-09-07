import 'package:arrow_fleet_manager/app/router_feature_screens_web.dart';
import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/permission_service.dart';
import 'package:arrow_fleet_manager/platform/platform_capabilities.dart';
import 'package:arrow_fleet_manager/platform/platform_runtime_web.dart';
import 'package:flutter/material.dart';
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

    test('central Dashboard and Fleet routes remain available', () {
      expect(supabaseWeb.routeAvailable('/dashboard'), isTrue);
      expect(supabaseWeb.routeAvailable('/vehicles'), isTrue);
    });

    test('local-only routes are unavailable', () {
      for (final route in <String>[
        '/drivers',
        '/users',
        '/calendar',
        '/workshop',
        '/compliance',
        '/reports',
        '/documents',
      ]) {
        expect(supabaseWeb.routeAvailable(route), isFalse, reason: route);
      }
    });

    test('native local and Supabase configurations remain compatible', () {
      for (final mode in BackendMode.values) {
        final capabilities = PlatformCapabilities(
          isWeb: false,
          backendMode: mode,
        );
        expect(capabilities.supportsApplicationConfiguration, isTrue);
        expect(capabilities.supportsLocalData, isTrue);
        expect(capabilities.routeAvailable('/drivers'), isTrue);
      }
    });
  });

  testWidgets('unsupported direct Web screen resolves safely', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DriverListScreen()));

    expect(
      find.text(
        'This feature is not yet available with the central web backend.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Web Dashboard renders only its central migration state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(
      find.text('Central dashboard metrics are still being migrated.'),
      findsOneWidget,
    );
    expect(find.text('Open Fleet'), findsOneWidget);
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
