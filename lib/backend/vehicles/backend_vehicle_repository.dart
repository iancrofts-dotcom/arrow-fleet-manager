import 'backend_vehicle.dart';
import 'backend_vehicle_gateway.dart';

class BackendVehicleRepository {
  const BackendVehicleRepository(this._gateway);

  final BackendVehicleGateway _gateway;

  Future<List<BackendVehicle>> listVehicles() async =>
      (await _gateway.listVehicles()).map(BackendVehicle.fromJson).toList();

  Future<BackendVehicle?> getVehicle(String id) async {
    final row = await _gateway.getVehicle(id);
    return row == null ? null : BackendVehicle.fromJson(row);
  }

  Future<BackendVehicle> insertVehicle(BackendVehicleWrite vehicle) async =>
      BackendVehicle.fromJson(
        await _gateway.insertVehicle(vehicle.toInsertJson()),
      );

  Future<BackendVehicle> updateVehicle(
    String id,
    BackendVehicleWrite vehicle,
  ) async => BackendVehicle.fromJson(
    await _gateway.updateVehicle(id, vehicle.toUpdateJson()),
  );
}
