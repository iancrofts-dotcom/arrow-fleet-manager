import 'package:arrow_fleet_manager/database/database_service.dart';
import 'package:arrow_fleet_manager/database/vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:arrow_fleet_manager/features/dashboard/services/dashboard_service.dart';
import 'package:arrow_fleet_manager/features/reports/services/fleet_report_service.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/services/vehicle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses persisted vehicle dates instead of driver compliance metrics',
    () async {
      final report = await _service(const []).generateReport();

      expect(report.motDue, 0);
      expect(report.serviceDue, 0);
      expect(report.overdue, 0);
    },
  );

  test(
    'counts vehicle MOT and service dates using fleet metric semantics',
    () async {
      final report = await _service([
        _vehicle(
          motExpiry: DateTime.now().add(const Duration(days: 5)),
          serviceDue: DateTime.now().add(const Duration(days: 10)),
        ),
      ]).generateReport();

      expect(report.motDue, 1);
      expect(report.serviceDue, 1);
      expect(report.overdue, 0);
    },
  );

  test(
    'counts overdue vehicle MOT dates without driver compliance input',
    () async {
      final report = await _service([
        _vehicle(motExpiry: DateTime.now().subtract(const Duration(days: 1))),
      ]).generateReport();

      expect(report.motDue, 0);
      expect(report.overdue, 1);
    },
  );

  test(
    'uses only vehicle dates when dashboard has driver compliance due data',
    () async {
      final report = await _service([
        _vehicle(
          motExpiry: DateTime.now().add(const Duration(days: 7)),
          serviceDue: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]).generateReport();

      expect(report.motDue, 1);
      expect(report.serviceDue, 0);
      expect(report.overdue, 1);
    },
  );

  test('retains the established inactive vehicle metric policy', () async {
    final inactiveVehicle = _vehicle(
      motExpiry: DateTime.now().add(const Duration(days: 5)),
    )..active = false;

    final report = await _service([inactiveVehicle]).generateReport();

    expect(report.motDue, 1);
  });
}

FleetReportService _service(List<Vehicle> vehicles) => FleetReportService(
  dashboardService: _FakeDashboardService(),
  vehicleService: _FakeVehicleService(vehicles),
);

Vehicle _vehicle({DateTime? motExpiry, DateTime? serviceDue}) => Vehicle(
  id: 1,
  registration: 'AB12 CDE',
  fleetNumber: 'F-1',
  make: 'Arrow',
  model: 'Van',
  year: 2026,
  vin: 'VIN-1',
  motExpiry: motExpiry,
  serviceDue: serviceDue,
);

class _FakeDashboardService extends DashboardService {
  @override
  Future<DashboardSummary> loadSummary() async => const DashboardSummary(
    vehicleCount: 0,
    driverCount: 0,
    activeVehicles: 0,
    activeDrivers: 0,
    assignedDrivers: 0,
    unassignedDrivers: 0,
    assignedVehicles: 0,
    unassignedVehicles: 0,
    maintenanceDue: 9,
    maintenanceOverdue: 8,
    complianceDue: 7,
    complianceExpired: 6,
    recentActivity: [],
    alerts: [],
  );
}

class _FakeVehicleService extends VehicleService {
  _FakeVehicleService(this._vehicles)
    : super(repository: VehicleRepository(databaseService: DatabaseService()));

  final List<Vehicle> _vehicles;

  @override
  Future<List<Vehicle>> getVehicles() async => _vehicles;
}
