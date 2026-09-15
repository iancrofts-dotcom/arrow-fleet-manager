import '../models/driver.dart';
import '../models/driver_identity.dart';

abstract interface class DriverDataSource {
  Future<List<Driver>> listDrivers();

  Future<Driver?> getDriver(DriverIdentity identity);
}
