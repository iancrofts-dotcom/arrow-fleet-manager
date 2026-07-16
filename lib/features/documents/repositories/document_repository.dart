import '../../../database/app_database.dart';
import '../models/fleet_document.dart';

class DocumentRepository {
  DocumentRepository();

  final AppDatabase _database = AppDatabase();

  static const tableName = 'fleet_documents';

  Future<List<FleetDocument>> getAll() async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      orderBy: 'expiryDate ASC',
    );

    return result
        .map(FleetDocument.fromMap)
        .toList();
  }

  Future<List<FleetDocument>> getByVehicle(
    int vehicleId,
  ) async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'expiryDate ASC',
    );

    return result
        .map(FleetDocument.fromMap)
        .toList();
  }

  Future<List<FleetDocument>> getByDriver(
    int driverId,
  ) async {
    final db = await _database.database();

    final result = await db.query(
      tableName,
      where: 'driverId = ?',
      whereArgs: [driverId],
      orderBy: 'expiryDate ASC',
    );

    return result
        .map(FleetDocument.fromMap)
        .toList();
  }

  Future<void> insert(
    FleetDocument document,
  ) async {
    final db = await _database.database();

    await db.insert(
      tableName,
      document.toMap(),
    );
  }

  Future<void> update(
    FleetDocument document,
  ) async {
    final db = await _database.database();

    await db.update(
      tableName,
      document.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  Future<void> delete(
    int id,
  ) async {
    final db = await _database.database();

    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> save(
    FleetDocument document,
  ) async {
    if (document.id == null) {
      await insert(document);
    } else {
      await update(document);
    }
  }
}