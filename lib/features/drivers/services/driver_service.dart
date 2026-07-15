import '../models/driver.dart';
import '../models/driver_entity.dart';
import '../repositories/driver_repository.dart';

class DriverService {
  DriverService({
    DriverRepository? repository,
  }) : _repository = repository ?? DriverRepository();

  final DriverRepository _repository;

  Future<List<Driver>> getDrivers() async {
    final entities = await _repository.getAllDrivers();

    return entities
        .map((entity) => entity.toDriver())
        .toList(growable: false);
  }

Future<Map<int, Driver>> getDriverMap() async {
  final drivers = await getDrivers();

  return {
    for (final driver in drivers)
      if (driver.id != null) driver.id!: driver,
  };
}

  Future<Driver?> getDriverById(
    int id,
  ) async {
    final entity =
        await _repository.getDriverById(id);

    return entity?.toDriver();
  }

  Future<bool> driverExists(
    int id,
  ) async {
    return await getDriverById(id) != null;
  }

  Future<void> addDriver(
    Driver driver,
  ) async {
    await _repository.insertDriver(
      DriverEntity.fromDriver(driver),
    );
  }

  Future<void> updateDriver(
    Driver driver,
  ) async {
    await _repository.updateDriver(
      DriverEntity.fromDriver(driver),
    );
  }

  Future<void> deleteDriver(
    int id,
  ) async {
    await _repository.deleteDriver(id);
  }
}