import '../../../database/app_database.dart';
import '../models/maintenance_record.dart';

class MaintenanceRepository {
  MaintenanceRepository();

  final AppDatabase _database = AppDatabase();

  static const String tableName = 'maintenance_records';

  Future<List<MaintenanceRecord>> getAll() async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      orderBy: 'due_date ASC',
    );

    return result
        .map(MaintenanceRecord.fromMap)
        .toList();
  }

  Future<List<MaintenanceRecord>> getForVehicle(
    int vehicleId,
  ) async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'due_date ASC',
    );

    return result
        .map(MaintenanceRecord.fromMap)
        .toList();
  }

  Future<MaintenanceRecord?> getById(
    int id,
  ) async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return MaintenanceRecord.fromMap(
      result.first,
    );
  }

  Future<int> insert(
    MaintenanceRecord record,
  ) async {
    final db = await _database.database();

    return db.insert(
      tableName,
      record.toMap(),
    );
  }

  Future<int> update(
    MaintenanceRecord record,
  ) async {
    final db = await _database.database();

    return db.update(
      tableName,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> save(
    MaintenanceRecord record,
  ) async {
    if (record.id == null) {
      await insert(record);
    } else {
      await update(record);
    }
  }

  Future<int> delete(
    int id,
  ) async {
    final db = await _database.database();

    return db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}