import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../../drivers/models/driver.dart';
import '../../vehicles/models/vehicle.dart';
import '../models/driver_assignment.dart';

class AssignmentRepository {
  AssignmentRepository._();

  static final AssignmentRepository instance =
      AssignmentRepository._();

  final AppDatabase _database = AppDatabase();

  Future<Database> get _db async => _database.database();

  // ------------------------------------------------------------
  // Get all assignments
  // ------------------------------------------------------------

  Future<List<DriverAssignment>> getAssignments() async {
    final db = await _db;

    final result = await db.query(
      'driver_assignments',
      orderBy: 'assigned_from DESC',
    );

    return result
        .map((e) => DriverAssignment.fromMap(e))
        .toList();
  }

  // ------------------------------------------------------------
  // Current assignment
  // ------------------------------------------------------------

  Future<DriverAssignment?> getCurrentAssignmentForDriver(
    int driverId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'driver_assignments',
      where: 'driver_id = ? AND active = 1',
      whereArgs: [driverId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DriverAssignment.fromMap(result.first);
  }

  Future<DriverAssignment?> getCurrentAssignmentForVehicle(
    int vehicleId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'driver_assignments',
      where: 'vehicle_id = ? AND active = 1',
      whereArgs: [vehicleId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return DriverAssignment.fromMap(result.first);
  }

  // ------------------------------------------------------------
  // Lookup Driver
  // ------------------------------------------------------------

  Future<Driver?> getAssignedDriver(
    int vehicleId,
  ) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT d.*
      FROM drivers d
      INNER JOIN driver_assignments da
        ON d.id = da.driver_id
      WHERE da.vehicle_id = ?
      AND da.active = 1
      LIMIT 1
      ''',
      [vehicleId],
    );

    if (result.isEmpty) {
      return null;
    }

    return Driver.fromMap(result.first);
  }

  // ------------------------------------------------------------
  // Lookup Vehicle
  // ------------------------------------------------------------

  Future<Vehicle?> getAssignedVehicle(
    int driverId,
  ) async {
    final db = await _db;

    final result = await db.rawQuery(
      '''
      SELECT v.*
      FROM vehicles v
      INNER JOIN driver_assignments da
        ON v.id = da.vehicle_id
      WHERE da.driver_id = ?
      AND da.active = 1
      LIMIT 1
      ''',
      [driverId],
    );

    if (result.isEmpty) {
      return null;
    }

    return Vehicle.fromMap(result.first);
  }

  // ------------------------------------------------------------
  // Assign Driver
  // ------------------------------------------------------------

  Future<void> assignDriver({
    required int driverId,
    required int vehicleId,
  }) async {
    final db = await _db;

    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Close existing assignment for driver
      await txn.update(
        'driver_assignments',
        {
          'active': 0,
          'assigned_to': now,
        },
        where: 'driver_id = ? AND active = 1',
        whereArgs: [driverId],
      );

      // Close existing assignment for vehicle
      await txn.update(
        'driver_assignments',
        {
          'active': 0,
          'assigned_to': now,
        },
        where: 'vehicle_id = ? AND active = 1',
        whereArgs: [vehicleId],
      );

      // Create new assignment
      await txn.insert(
        'driver_assignments',
        {
          'driver_id': driverId,
          'vehicle_id': vehicleId,
          'assigned_from': now,
          'assigned_to': null,
          'active': 1,
        },
      );
    });
  }

  // ------------------------------------------------------------
  // End Assignment
  // ------------------------------------------------------------

  Future<void> endAssignment(
    int assignmentId,
  ) async {
    final db = await _db;

    await db.update(
      'driver_assignments',
      {
        'active': 0,
        'assigned_to':
            DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [assignmentId],
    );
  }

  // ------------------------------------------------------------
  // Unassign Vehicle
  // ------------------------------------------------------------

  Future<void> unassignVehicle(
    int vehicleId,
  ) async {
    final db = await _db;

    await db.update(
      'driver_assignments',
      {
        'active': 0,
        'assigned_to':
            DateTime.now().millisecondsSinceEpoch,
      },
      where: 'vehicle_id = ? AND active = 1',
      whereArgs: [vehicleId],
    );
  }

  // ------------------------------------------------------------
  // Unassign Driver
  // ------------------------------------------------------------

  Future<void> unassignDriver(
    int driverId,
  ) async {
    final db = await _db;

    await db.update(
      'driver_assignments',
      {
        'active': 0,
        'assigned_to':
            DateTime.now().millisecondsSinceEpoch,
      },
      where: 'driver_id = ? AND active = 1',
      whereArgs: [driverId],
    );
  }

  // ------------------------------------------------------------
  // Driver History
  // ------------------------------------------------------------

  Future<List<DriverAssignment>> getDriverHistory(
    int driverId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'driver_assignments',
      where: 'driver_id = ?',
      whereArgs: [driverId],
      orderBy: 'assigned_from DESC',
    );

    return result
        .map((e) => DriverAssignment.fromMap(e))
        .toList();
  }

  // ------------------------------------------------------------
  // Vehicle History
  // ------------------------------------------------------------
Future<List<Map<String, dynamic>>> getVehicleAssignmentHistory(
  int vehicleId,
) async {
  final db = await _db;

  return await db.rawQuery(
    '''
    SELECT
      da.id,
      da.driver_id,
      da.vehicle_id,
      da.assigned_from,
      da.assigned_to,
      da.active,
      d.first_name,
      d.last_name,
      d.licence_number
    FROM driver_assignments da
    INNER JOIN drivers d
      ON d.id = da.driver_id
    WHERE da.vehicle_id = ?
    ORDER BY da.assigned_from DESC
    ''',
    [vehicleId],
  );
}
  Future<List<DriverAssignment>> getVehicleHistory(
    int vehicleId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'driver_assignments',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'assigned_from DESC',
    );

    return result
        .map((e) => DriverAssignment.fromMap(e))
        .toList();
  }
}
