import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../models/driver_entity.dart';

class DriverRepository {
  DriverRepository();

  final AppDatabase _database = AppDatabase();

  Future<Database> get _db async =>
      _database.database();

  Future<List<DriverEntity>> getAllDrivers() async {
    final db = await _db;

    final maps = await db.query(
      'drivers',
      orderBy: 'last_name ASC, first_name ASC',
    );

    return maps
        .map(DriverEntity.fromMap)
        .toList();
  }

  Future<DriverEntity?> getDriverById(
    int id,
  ) async {
    final db = await _db;

    final maps = await db.query(
      'drivers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return DriverEntity.fromMap(
      maps.first,
    );
  }

  Future<int> insertDriver(
    DriverEntity driver,
  ) async {
    final db = await _db;

    return db.insert(
      'drivers',
      driver.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<int> updateDriver(
    DriverEntity driver,
  ) async {
    final db = await _db;

    return db.update(
      'drivers',
      driver.toMap(),
      where: 'id = ?',
      whereArgs: [driver.id],
    );
  }

  Future<int> deleteDriver(
    int id,
  ) async {
    final db = await _db;

    return db.delete(
      'drivers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}