import '../models/driver.dart';
import '../models/driver_creation_request.dart';
import '../models/driver_entity.dart';
import '../repositories/driver_assignment_repository.dart';
import '../repositories/driver_repository.dart';
import '../../auth/services/user_sync_service.dart';
import '../../auth/models/user.dart';
import '../../auth/services/user_service.dart';
import 'driver_username_service.dart';

class DriverService {
  DriverService({
    DriverRepository? repository,
    UserSyncService? userSyncService,
    UserService? userService,
    DriverAssignmentRepository? assignmentRepository,
    DriverUsernameService? usernameService,
  }) : _repository = repository ?? DriverRepository(),
       _userSyncService = userSyncService ?? UserSyncService.instance,
       _userService = userService ?? UserService.instance,
       _assignmentRepository =
           assignmentRepository ?? DriverAssignmentRepository(),
       _usernameService = usernameService ?? DriverUsernameService();

  final DriverRepository _repository;
  final UserSyncService _userSyncService;
  final UserService _userService;
  final DriverAssignmentRepository _assignmentRepository;
  final DriverUsernameService _usernameService;

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
    if (request.password.isEmpty) {
      throw ArgumentError('A password is required to create a driver account.');
    }

    final username = await _usernameService.generateUsername(
      firstName: driver.firstName,
      lastName: driver.lastName,
    );
    final driverWithUsername = driver.copyWith(username: username);

    int? insertedDriverId;
    try {
      insertedDriverId = await _repository.insertDriver(
        DriverEntity.fromDriver(driverWithUsername),
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

  /// Updates a Driver-linked account without allowing the two persisted
  /// username fields to diverge.
  ///
  /// Driver and User repositories do not currently share a transaction
  /// executor. The Driver write is therefore compensated with the exact
  /// original record if the following User write fails.
  Future<void> updateDriverLinkedAccount(
    User user, {
    required String username,
    String? newPassword,
  }) async {
    final driverId = user.driverId;
    if (driverId == null) {
      throw ArgumentError('A linked Driver account is required.');
    }

    final persistedUser = await _userService.getUserById(user.id);
    if (persistedUser == null || persistedUser.driverId != driverId) {
      throw StateError('The linked Driver account could not be verified.');
    }

    if (!await _userService.isUsernameAvailable(
      username,
      excludingUserId: persistedUser.id,
    )) {
      throw StateError('Username already exists.');
    }

    final existingDriver = await getDriverById(driverId);
    if (existingDriver == null) {
      throw StateError('The linked Driver record could not be found.');
    }

    final updatedDriver = existingDriver.copyWith(username: username);
    final updatedUser = persistedUser.copyWith(username: username);
    var driverUpdated = false;

    try {
      final updatedRows = await _repository.updateDriver(
        DriverEntity.fromDriver(updatedDriver),
      );
      if (updatedRows != 1) {
        throw StateError('The linked Driver record could not be updated.');
      }
      driverUpdated = true;

      await _userService.updateUser(updatedUser, newPassword: newPassword);
    } catch (error, stackTrace) {
      if (driverUpdated) {
        try {
          final restoredRows = await _repository.updateDriver(
            DriverEntity.fromDriver(existingDriver),
          );
          if (restoredRows != 1) {
            throw StateError('The linked Driver record could not be restored.');
          }
        } catch (rollbackError) {
          throw StateError(
            'Driver account update failed: $error. '
            'Unable to restore the linked Driver: $rollbackError.',
          );
        }
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// Deactivates a driver while retaining their account and historical records.
  Future<void> deactivateDriver(int id) async {
    final entity = await _repository.getDriverById(id);
    if (entity == null) {
      throw StateError('Driver $id could not be found.');
    }

    final activeAssignment = await _assignmentRepository
        .getCurrentAssignmentForDriver(id);
    if (activeAssignment != null) {
      await _assignmentRepository.updateAssignment(
        activeAssignment.copyWith(assignedTo: DateTime.now(), active: false),
      );
    }

    final inactiveDriver = entity.toDriver().copyWith(isActive: false);
    await _repository.updateDriver(DriverEntity.fromDriver(inactiveDriver));
    await _userSyncService.syncDriver(inactiveDriver);
  }
}
