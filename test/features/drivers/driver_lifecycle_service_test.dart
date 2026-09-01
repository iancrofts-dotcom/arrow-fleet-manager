import 'package:arrow_fleet_manager/database/database_service.dart';
import 'package:arrow_fleet_manager/database/vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/auth/services/user_sync_service.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_entity.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_vehicle_assignment.dart';
import 'package:arrow_fleet_manager/features/drivers/repositories/driver_assignment_repository.dart';
import 'package:arrow_fleet_manager/features/drivers/repositories/driver_repository.dart';
import 'package:arrow_fleet_manager/features/drivers/services/driver_assignment_service.dart';
import 'package:arrow_fleet_manager/features/drivers/services/driver_service.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/services/vehicle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'driver deactivation ends its active assignment and retains the driver',
    () async {
      final drivers = _FakeDriverRepository()
        ..seed(_driver(id: 1, isActive: true));
      final assignments = _FakeAssignmentRepository()
        ..seed(_assignment(driverId: 1, vehicleId: 2));
      final users = _RecordingUserSyncService();
      final service = DriverService(
        repository: drivers,
        userSyncService: users,
        assignmentRepository: assignments,
      );

      await service.deactivateDriver(1);

      expect(drivers.driver(1)!.isActive, isFalse);
      expect(assignments.assignment(1)!.active, isFalse);
      expect(assignments.assignment(1)!.assignedTo, isNotNull);
      expect(users.syncedDriver!.id, 1);
      expect(users.syncedDriver!.isActive, isFalse);
    },
  );

  test(
    'vehicle deactivation ends its active assignment and retains the vehicle',
    () async {
      final vehicles = _FakeVehicleRepository()..seed(_vehicle(id: 2));
      final assignments = _FakeAssignmentRepository()
        ..seed(_assignment(driverId: 1, vehicleId: 2));
      final service = VehicleService(
        repository: vehicles,
        assignmentRepository: assignments,
      );

      await service.deactivateVehicle(2);

      expect(vehicles.vehicle(2)!.active, isFalse);
      expect(assignments.assignment(1)!.active, isFalse);
      expect(assignments.assignment(1)!.assignedTo, isNotNull);
    },
  );

  test('inactive drivers and vehicles cannot receive assignments', () async {
    final assignments = _FakeAssignmentRepository();
    final inactiveDriverRepository = _FakeDriverRepository()
      ..seed(_driver(id: 1, isActive: false));
    final activeVehicleRepository = _FakeVehicleRepository()
      ..seed(_vehicle(id: 2));
    final serviceWithInactiveDriver = DriverAssignmentService(
      repository: assignments,
      driverService: DriverService(repository: inactiveDriverRepository),
      vehicleService: VehicleService(repository: activeVehicleRepository),
    );

    await expectLater(
      serviceWithInactiveDriver.assignDriver(driverId: 1, vehicleId: 2),
      throwsStateError,
    );

    final activeDriverRepository = _FakeDriverRepository()
      ..seed(_driver(id: 1, isActive: true));
    final inactiveVehicleRepository = _FakeVehicleRepository()
      ..seed(_vehicle(id: 2, active: false));
    final serviceWithInactiveVehicle = DriverAssignmentService(
      repository: assignments,
      driverService: DriverService(repository: activeDriverRepository),
      vehicleService: VehicleService(repository: inactiveVehicleRepository),
    );

    await expectLater(
      serviceWithInactiveVehicle.assignDriver(driverId: 1, vehicleId: 2),
      throwsStateError,
    );
  });

  test('vehicle reactivation retains ended assignment history', () async {
    final vehicles = _FakeVehicleRepository()
      ..seed(_vehicle(id: 2, active: false));
    final assignments = _FakeAssignmentRepository()
      ..seed(
        _assignment(
          driverId: 1,
          vehicleId: 2,
        ).copyWith(assignedTo: DateTime(2026, 2, 1), active: false),
      );
    final service = VehicleService(
      repository: vehicles,
      assignmentRepository: assignments,
    );

    await service.reactivateVehicle(2);

    expect(vehicles.vehicle(2)!.active, isTrue);
    expect(assignments.assignment(1)!.active, isFalse);
    expect(assignments.assignment(1)!.assignedTo, DateTime(2026, 2, 1));
  });
}

class _FakeDriverRepository extends DriverRepository {
  final _drivers = <int, DriverEntity>{};

  void seed(Driver driver) =>
      _drivers[driver.id!] = DriverEntity.fromDriver(driver);

  Driver? driver(int id) => _drivers[id]?.toDriver();

  @override
  Future<DriverEntity?> getDriverById(int id) async => _drivers[id];

  @override
  Future<int> updateDriver(DriverEntity driver) async {
    _drivers[driver.id!] = driver;
    return 1;
  }
}

class _FakeVehicleRepository extends VehicleRepository {
  _FakeVehicleRepository() : super(databaseService: DatabaseService());

  final _vehicles = <int, Vehicle>{};

  void seed(Vehicle vehicle) => _vehicles[vehicle.id!] = vehicle;

  Vehicle? vehicle(int id) => _vehicles[id];

  @override
  Future<Vehicle?> getVehicleById(int id) async => _vehicles[id];

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    _vehicles[vehicle.id!] = vehicle;
  }
}

class _FakeAssignmentRepository extends DriverAssignmentRepository {
  final _assignments = <int, DriverVehicleAssignment>{};

  void seed(DriverVehicleAssignment assignment) =>
      _assignments[assignment.id!] = assignment;

  DriverVehicleAssignment? assignment(int id) => _assignments[id];

  @override
  Future<DriverVehicleAssignment?> getCurrentAssignmentForDriver(
    int driverId,
  ) async {
    for (final assignment in _assignments.values) {
      if (assignment.driverId == driverId && assignment.active) {
        return assignment;
      }
    }
    return null;
  }

  @override
  Future<DriverVehicleAssignment?> getCurrentAssignmentForVehicle(
    int vehicleId,
  ) async {
    for (final assignment in _assignments.values) {
      if (assignment.vehicleId == vehicleId && assignment.active) {
        return assignment;
      }
    }
    return null;
  }

  @override
  Future<int> updateAssignment(DriverVehicleAssignment assignment) async {
    _assignments[assignment.id!] = assignment;
    return 1;
  }
}

class _RecordingUserSyncService extends UserSyncService {
  Driver? syncedDriver;

  @override
  Future<void> syncDriver(Driver driver) async {
    syncedDriver = driver;
  }
}

DriverVehicleAssignment _assignment({
  required int driverId,
  required int vehicleId,
}) => DriverVehicleAssignment(
  id: 1,
  driverId: driverId,
  vehicleId: vehicleId,
  assignedFrom: DateTime(2026, 1, 1),
);

Driver _driver({required int id, required bool isActive}) => Driver(
  id: id,
  firstName: 'Alex',
  lastName: 'Driver',
  licenceNumber: 'LIC-100',
  username: 'alex.driver',
  isActive: isActive,
);

Vehicle _vehicle({required int id, bool active = true}) => Vehicle(
  id: id,
  registration: 'AB12 CDE',
  fleetNumber: 'FLEET-1',
  make: 'Arrow',
  model: 'Van',
  year: 2026,
  vin: 'VIN-1',
  active: active,
);
