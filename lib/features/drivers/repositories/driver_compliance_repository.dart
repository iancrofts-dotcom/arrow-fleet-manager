import '../../../database/app_database.dart';
import '../models/driver_compliance.dart';

class DriverComplianceRepository {
  DriverComplianceRepository();

  final AppDatabase _database = AppDatabase();

  static const String tableName = 'driver_compliance';

  Future<List<DriverCompliance>> getAll() async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      orderBy: 'driverId ASC',
    );

    return result
        .map(DriverCompliance.fromMap)
        .toList();
  }

  Future<DriverCompliance?> getByDriverId(
    int driverId,
  ) async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      where: 'driverId = ?',
      whereArgs: [driverId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return DriverCompliance.fromMap(
      result.first,
    );
  }

  Future<void> insert(
    DriverCompliance compliance,
  ) async {
    final db = await _database.database();

    await db.insert(
      tableName,
      compliance.toMap(),
    );
  }

  Future<void> update(
    DriverCompliance compliance,
  ) async {
    final db = await _database.database();

    await db.update(
      tableName,
      compliance.toMap(),
      where: 'driverId = ?',
      whereArgs: [compliance.driverId],
    );
  }

  Future<void> save(
    DriverCompliance compliance,
  ) async {
    final existing =
        await getByDriverId(
      compliance.driverId,
    );

    if (existing == null) {
      await insert(compliance);
    } else {
      await update(compliance);
    }
  }

  Future<void> delete(
    int driverId,
  ) async {
    final db = await _database.database();

    await db.delete(
      tableName,
      where: 'driverId = ?',
      whereArgs: [driverId],
    );
  }
}