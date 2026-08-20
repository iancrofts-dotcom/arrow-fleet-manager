import '../models/driver.dart';
import '../models/driver_creation_request.dart';
import '../models/driver_entity.dart';
import '../repositories/driver_repository.dart';
import '../../auth/services/user_sync_service.dart';

class DriverService {
  DriverService({
    DriverRepository? repository,
    UserSyncService? userSyncService,
  }) : _repository = repository ?? DriverRepository(),
       _userSyncService = userSyncService ?? UserSyncService.instance;

  final DriverRepository _repository;
  final UserSyncService _userSyncService;

  Future<List<Driver>> getDrivers() async {
    final entities = await _repository.getAllDrivers();

    return entities.map((entity) => entity.toDriver()).toList(growable: false);
  }

  Future<Map<int, Driver>> getDriverMap() async {
    final drivers = await getDrivers();

    return {
      for (final driver in drivers)
        if (driver.id != null) driver.id!: driver,
    };
  }

  Future<Driver?> getDriverById(int id) async {
    final entity = await _repository.getDriverById(id);

    return entity?.toDriver();
  }

  Future<bool> driverExists(int id) async {
    return await getDriverById(id) != null;
  }

  /// Adds a driver and returns the saved database record,
  /// including the generated ID.
  Future<Driver> addDriver(DriverCreationRequest request) async {
    final driver = request.driver;
    final username = driver.username;
    if (username == null || username.isEmpty) {
      throw ArgumentError('A username is required to create a driver account.');
    }
    if (request.password.isEmpty) {
      throw ArgumentError('A password is required to create a driver account.');
    }

    if (await _userSyncService.isUsernameInUse(username)) {
      throw StateError('Username already exists.');
    }

    int? insertedDriverId;
    try {
      insertedDriverId = await _repository.insertDriver(
        DriverEntity.fromDriver(driver),
      );

      final savedEntity = await _repository.getDriverById(insertedDriverId);
      if (savedEntity == null) {
        throw StateError(
          'Inserted driver $insertedDriverId could not be retrieved.',
        );
      }

      final savedDriver = savedEntity.toDriver();
      await _userSyncService.createDriverUser(
        savedDriver,
        password: request.password,
      );

      return savedDriver;
    } catch (error, stackTrace) {
      if (insertedDriverId != null) {
        try {
          await _repository.deleteDriver(insertedDriverId);
        } catch (cleanupError) {
          throw StateError(
            'Driver creation failed: $error. '
            'Unable to remove the newly created driver: $cleanupError.',
          );
        }
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateDriver(Driver driver) async {
    await _repository.updateDriver(DriverEntity.fromDriver(driver));

    await _userSyncService.syncDriver(driver);
  }

  Future<void> deleteDriver(int id) async {
    await _repository.deleteDriver(id);

    await _userSyncService.deleteDriverUser(id);
  }
}
