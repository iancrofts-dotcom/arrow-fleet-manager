import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../models/driver_vehicle_assignment.dart';

class DriverAssignmentRepository {
  DriverAssignmentRepository();

  final AppDatabase _database = AppDatabase();

  Future<Database> get _db async =>
      _database.database();

  Future<List<DriverVehicleAssignment>>
      getAllAssignments() async {
    final db = await _db;

    final maps = await db.query(
      'driver_assignments',
      orderBy: 'assigned_from DESC',
    );

    return maps
        .map(
          DriverVehicleAssignment.fromMap,
        )
        .toList();
  }

  Future<List<DriverVehicleAssignment>>
      getActiveAssignments() async {
    final db = await _db;

    final maps = await db.query(
      'driver_assignments',
      where: 'active = ?',
      whereArgs: [1],
      orderBy: 'assigned_from DESC',
    );

    return maps
        .map(
          DriverVehicleAssignment.fromMap,
        )
        .toList();
  }

  Future<DriverVehicleAssignment?>
      getCurrentAssignmentForDriver(
    int driverId,
  ) async {
    final db = await _db;

    final maps = await db.query(
      'driver_assignments',
      where:
          'driver_id = ? AND active = ?',
      whereArgs: [driverId, 1],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return DriverVehicleAssignment.fromMap(
      maps.first,
    );
  }

  Future<DriverVehicleAssignment?>
      getCurrentAssignmentForVehicle(
    int vehicleId,
  ) async {
    final db = await _db;

    final maps = await db.query(
      'driver_assignments',
      where:
          'vehicle_id = ? AND active = ?',
      whereArgs: [vehicleId, 1],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return DriverVehicleAssignment.fromMap(
      maps.first,
    );
  }

  Future<int> insertAssignment(
    DriverVehicleAssignment assignment,
  ) async {
    final db = await _db;

    return db.insert(
      'driver_assignments',
      assignment.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<int> updateAssignment(
    DriverVehicleAssignment assignment,
  ) async {
    final db = await _db;

    return db.update(
      'driver_assignments',
      assignment.toMap(),
      where: 'id = ?',
      whereArgs: [assignment.id],
    );
  }

  Future<int> deleteAssignment(
    int id,
  ) async {
    final db = await _db;

    return db.delete(
      'driver_assignments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}