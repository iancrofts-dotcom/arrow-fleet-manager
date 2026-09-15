import '../models/driver.dart';
import '../models/driver_identity.dart';
import 'driver_data_source.dart';
import 'driver_service.dart';

class LocalDriverDataSource implements DriverDataSource {
  LocalDriverDataSource([DriverService? service])
    : _service = service ?? DriverService();

  final DriverService _service;

  @override
  Future<List<Driver>> listDrivers() => _service.getDrivers();

  @override
  Future<Driver?> getDriver(DriverIdentity identity) =>
      _service.getDriverById(identity.requireLocalId('Driver lookup'));
}
