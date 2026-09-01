import 'package:arrow_fleet_manager/database/database_service.dart';
import 'package:arrow_fleet_manager/database/vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/services/vehicle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'returns the exact inserted vehicle ID for duplicate-looking vehicles',
    () async {
      final repository = _FakeVehicleRepository();
      final service = VehicleService(repository: repository);
      final first = await service.addVehicle(
        _vehicle(fleetNumber: 'FLEET-1', vin: 'VIN-1'),
      );
      final second = await service.addVehicle(
        _vehicle(fleetNumber: 'FLEET-2', vin: 'VIN-2'),
      );

      expect(first.id, 1);
      expect(second.id, 2);
      expect(first.registration, second.registration);
      expect(first.make, second.make);
      expect(first.model, second.model);
      expect(first.fleetNumber, 'FLEET-1');
      expect(first.vin, 'VIN-1');
      expect(second.fleetNumber, 'FLEET-2');
      expect(second.vin, 'VIN-2');
    },
  );

  test('updates and clears persisted MOT and service dates', () async {
    final repository = _FakeVehicleRepository();
    final service = VehicleService(repository: repository);
    final originalMotExpiry = DateTime(2026, 9, 1);
    final originalServiceDue = DateTime(2026, 9, 15);
    final saved = await service.addVehicle(
      _vehicle(
        fleetNumber: 'FLEET-1',
        vin: 'VIN-1',
        motExpiry: originalMotExpiry,
        serviceDue: originalServiceDue,
      ),
    );
    final motExpiry = DateTime(2026, 10, 1);
    final serviceDue = DateTime(2026, 11, 1);

    await service.updateVehicle(
      _updatedVehicle(
        saved,
        motExpiry: motExpiry,
        serviceDue: originalServiceDue,
      ),
    );

    var persisted = await repository.getVehicleById(saved.id!);
    expect(persisted!.motExpiry, motExpiry);
    expect(persisted.serviceDue, originalServiceDue);

    await service.updateVehicle(
      _updatedVehicle(saved, motExpiry: motExpiry, serviceDue: serviceDue),
    );

    persisted = await repository.getVehicleById(saved.id!);
    expect(persisted!.motExpiry, motExpiry);
    expect(persisted.serviceDue, serviceDue);

    await service.updateVehicle(
      _updatedVehicle(saved, motExpiry: null, serviceDue: serviceDue),
    );

    persisted = await repository.getVehicleById(saved.id!);
    expect(persisted!.motExpiry, isNull);
    expect(persisted.serviceDue, serviceDue);

    await service.updateVehicle(
      _updatedVehicle(saved, motExpiry: motExpiry, serviceDue: null),
    );

    persisted = await repository.getVehicleById(saved.id!);
    expect(persisted!.motExpiry, motExpiry);
    expect(persisted.serviceDue, isNull);

    await service.updateVehicle(
      _updatedVehicle(saved, motExpiry: null, serviceDue: null),
    );

    persisted = await repository.getVehicleById(saved.id!);
    expect(persisted!.motExpiry, isNull);
    expect(persisted.serviceDue, isNull);
    expect(persisted.registration, saved.registration);
    expect(persisted.fleetNumber, saved.fleetNumber);
  });
}

class _FakeVehicleRepository extends VehicleRepository {
  _FakeVehicleRepository() : super(databaseService: DatabaseService());

  final _vehicles = <int, Vehicle>{};
  var _nextId = 1;

  @override
  Future<int> addVehicle(Vehicle vehicle) async {
    final id = _nextId++;
    _vehicles[id] = Vehicle(
      id: id,
      fleetNumber: vehicle.fleetNumber,
      registration: vehicle.registration,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      vin: vehicle.vin,
      motExpiry: vehicle.motExpiry,
      serviceDue: vehicle.serviceDue,
      active: vehicle.active,
    );
    return id;
  }

  @override
  Future<Vehicle?> getVehicleById(int id) async => _vehicles[id];

  @override
  Future<void> updateVehicle(Vehicle vehicle) async {
    _vehicles[vehicle.id!] = Vehicle(
      id: vehicle.id,
      fleetNumber: vehicle.fleetNumber,
      registration: vehicle.registration,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      vin: vehicle.vin,
      motExpiry: vehicle.motExpiry,
      serviceDue: vehicle.serviceDue,
      active: vehicle.active,
    );
  }
}

Vehicle _vehicle({
  required String fleetNumber,
  required String vin,
  DateTime? motExpiry,
  DateTime? serviceDue,
}) => Vehicle(
  fleetNumber: fleetNumber,
  registration: 'AB12 CDE',
  make: 'Arrow',
  model: 'Van',
  year: 2026,
  vin: vin,
  motExpiry: motExpiry,
  serviceDue: serviceDue,
);

Vehicle _updatedVehicle(
  Vehicle vehicle, {
  required DateTime? motExpiry,
  required DateTime? serviceDue,
}) => Vehicle(
  id: vehicle.id,
  fleetNumber: vehicle.fleetNumber,
  registration: vehicle.registration,
  make: vehicle.make,
  model: vehicle.model,
  year: vehicle.year,
  vin: vehicle.vin,
  motExpiry: motExpiry,
  serviceDue: serviceDue,
  active: vehicle.active,
);
