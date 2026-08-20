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
}

Vehicle _vehicle({required String fleetNumber, required String vin}) => Vehicle(
  fleetNumber: fleetNumber,
  registration: 'AB12 CDE',
  make: 'Arrow',
  model: 'Van',
  year: 2026,
  vin: vin,
);
