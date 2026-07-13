import '../models/driver.dart';

class DriverService {
  DriverService();

  final List<Driver> _drivers = [];

  Future<List<Driver>> getDrivers() async {
    return List.unmodifiable(_drivers);
  }

  Future<void> addDriver(
    Driver driver,
  ) async {
    _drivers.add(driver);
  }

  Future<void> updateDriver(
    Driver driver,
  ) async {
    final index = _drivers.indexWhere(
      (d) => d.id == driver.id,
    );

    if (index != -1) {
      _drivers[index] = driver;
    }
  }

  Future<void> deleteDriver(
    int id,
  ) async {
    _drivers.removeWhere(
      (d) => d.id == id,
    );
  }
}