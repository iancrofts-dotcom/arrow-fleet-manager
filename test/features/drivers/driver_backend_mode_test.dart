import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:arrow_fleet_manager/features/auth/models/user_role.dart';
import 'package:arrow_fleet_manager/features/auth/services/auth_service.dart';
import 'package:arrow_fleet_manager/features/auth/services/permission_service.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_identity.dart';
import 'package:arrow_fleet_manager/features/drivers/screens/central_driver_list_screen.dart'
    as web;
import 'package:arrow_fleet_manager/features/drivers/screens/driver_list_screen.dart'
    as native;
import 'package:arrow_fleet_manager/features/drivers/services/driver_data_source.dart';
import 'package:arrow_fleet_manager/features/drivers/services/driver_read_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _uuid = '123e4567-e89b-42d3-a456-426614174000';

Driver _centralDriver() => Driver(
  identity: DriverIdentity.central(_uuid),
  firstName: 'Central',
  lastName: 'Driver',
  licenceNumber: 'LIVE-DRIVER',
  email: 'central@example.invalid',
);

void main() {
  test('Supabase mode selects only the central Driver source', () async {
    final local = _FakeDataSource(const []);
    final central = _FakeDataSource([_centralDriver()]);
    final service = DriverReadService.forMode(
      BackendMode.supabase,
      localDataSource: local,
      supabaseDataSource: central,
    );

    final drivers = await service.getDrivers();

    expect(central.listCalls, 1);
    expect(local.listCalls, 0);
    expect(drivers.single.id, isNull);
    expect(drivers.single.identity?.centralIdOrNull, _uuid);
  });

  test('local mode selects only the SQLite Driver adapter', () async {
    final local = _FakeDataSource(const []);
    final central = _FakeDataSource(const []);
    final service = DriverReadService.forMode(
      BackendMode.local,
      localDataSource: local,
      supabaseDataSource: central,
    );

    await service.getDrivers();

    expect(local.listCalls, 1);
    expect(central.listCalls, 0);
  });

  test('central failure propagates without local fallback', () async {
    final local = _FakeDataSource(const []);
    final central = _FakeDataSource(const [], error: StateError('remote'));
    final service = DriverReadService.forMode(
      BackendMode.supabase,
      localDataSource: local,
      supabaseDataSource: central,
    );

    await expectLater(service.getDrivers(), throwsStateError);
    expect(local.listCalls, 0);
  });

  testWidgets('central Web list is read-only and navigates by UUID-safe data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = DriverReadService(_FakeDataSource([_centralDriver()]));
    await tester.pumpWidget(
      MaterialApp(
        home: web.DriverListScreen(
          driverReadService: service,
          permissions: _permissions(UserRole.admin),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Central Driver'), findsOneWidget);
    expect(find.text('Add Driver'), findsNothing);
    expect(find.byType(Dismissible), findsNothing);

    await tester.tap(find.text('Central Driver'));
    await tester.pumpAndSettle();
    expect(
      find.text('Driver profile, assignment and compliance records.'),
      findsOneWidget,
    );
    // Detail editing is guarded by the application PermissionService singleton;
    // this focused Web fixture only proves UUID-safe navigation and that
    // assignment mutation remains unavailable.
    expect(find.text('Assign Vehicle'), findsNothing);
  });

  testWidgets('native Supabase list enables central Driver creation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: native.DriverListScreen(
          backendMode: BackendMode.supabase,
          driverReadService: DriverReadService(
            _FakeDataSource([_centralDriver()]),
          ),
          permissions: _permissions(UserRole.admin),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Central Driver'), findsOneWidget);
    expect(find.text('Add Driver'), findsOneWidget);
    expect(find.byType(Dismissible), findsOneWidget);
  });

  testWidgets('local list retains Administrator write actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: native.DriverListScreen(
          backendMode: BackendMode.local,
          driverReadService: DriverReadService(_FakeDataSource(const [])),
          permissions: _permissions(UserRole.admin),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Driver'), findsOneWidget);
  });

  testWidgets('central Driver list retains application role guards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: web.DriverListScreen(
          driverReadService: DriverReadService(
            _FakeDataSource([_centralDriver()]),
          ),
          permissions: _permissions(UserRole.driver),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('You do not have permission to view drivers.'),
      findsOneWidget,
    );
    expect(find.text('Central Driver'), findsNothing);
  });
}

PermissionService _permissions(UserRole role) =>
    PermissionService(authService: _RoleAuthService(role));

class _RoleAuthService extends AuthService {
  _RoleAuthService(this.role) : super(enableSessionWatchdog: false);

  final UserRole role;

  @override
  UserRole? get currentRole => role;
}

class _FakeDataSource implements DriverDataSource {
  _FakeDataSource(this.drivers, {this.error});

  final List<Driver> drivers;
  final Object? error;
  int listCalls = 0;

  @override
  Future<List<Driver>> listDrivers() async {
    listCalls++;
    if (error case final failure?) throw failure;
    return drivers;
  }

  @override
  Future<Driver?> getDriver(DriverIdentity identity) async =>
      drivers.where((driver) => driver.identity == identity).firstOrNull;
}
