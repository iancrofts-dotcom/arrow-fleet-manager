import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle_filter.dart';
import 'package:arrow_fleet_manager/features/vehicles/services/vehicle_filter_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('All vehicle filter retains inactive vehicles for reactivation', () {
    const service = VehicleFilterService();
    final activeVehicle = _vehicle(id: 1, active: true);
    final inactiveVehicle = _vehicle(id: 2, active: false);

    final vehicles = service.filterVehicles(
      vehicles: [activeVehicle, inactiveVehicle],
      filter: VehicleFilter.all,
    );

    expect(vehicles, [activeVehicle, inactiveVehicle]);
  });
}

Vehicle _vehicle({required int id, required bool active}) => Vehicle(
  id: id,
  registration: 'AB12 CDE',
  fleetNumber: 'FLEET-$id',
  make: 'Arrow',
  model: 'Van',
  year: 2026,
  vin: 'VIN-$id',
  active: active,
);
