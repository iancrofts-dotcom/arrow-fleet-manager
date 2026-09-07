import '../models/vehicle.dart';
import '../models/vehicle_identity.dart';

abstract interface class VehicleDataSource {
  Future<List<Vehicle>> listVehicles();
  Future<int> getVehicleCount();
  Future<Vehicle?> getVehicle(VehicleIdentity identity);
  Future<Vehicle> addVehicle(Vehicle vehicle);
  Future<Vehicle> updateVehicle(Vehicle vehicle);
}
