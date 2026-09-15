import 'backend_driver.dart';
import 'backend_driver_gateway.dart';

class BackendDriverRepository {
  const BackendDriverRepository(this._gateway);
  final BackendDriverGateway _gateway;
  Future<List<BackendDriver>> listDrivers() async =>
      (await _gateway.listDrivers()).map(BackendDriver.fromJson).toList();
  Future<BackendDriver?> getDriver(String id) async {
    final row = await _gateway.getDriver(id);
    return row == null ? null : BackendDriver.fromJson(row);
  }

  Future<BackendDriver> insertDriver(BackendDriverWrite driver) async =>
      BackendDriver.fromJson(
        await _gateway.insertDriver(driver.toInsertJson()),
      );
  Future<BackendDriver> updateDriver(
    String id,
    BackendDriverWrite driver,
  ) async => BackendDriver.fromJson(
    await _gateway.updateDriver(id, driver.toUpdateJson()),
  );
}
