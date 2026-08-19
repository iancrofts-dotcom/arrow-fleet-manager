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
      where: 'isArchived = 0',
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
      where: 'vehicleId = ? AND isArchived = 0',
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
      where: 'driverId = ? AND isArchived = 0',
      whereArgs: [driverId],
      orderBy: 'expiryDate ASC',
    );

    return result
        .map(FleetDocument.fromMap)
        .toList();
  }

  Future<int> insert(
    FleetDocument document,
  ) async {
    final db = await _database.database();

    return db.insert(
      tableName,
      document.toMap(),
    );
  }

  Future<FleetDocument?> getCurrentComplianceDocument(
    int driverId,
    DocumentCategory category,
  ) async {
    final db = await _database.database();
    final result = await db.query(
      tableName,
      where: 'driverId = ? AND category = ? AND isArchived = 0',
      whereArgs: [driverId, category.name],
      orderBy: 'lastUpdated DESC',
      limit: 1,
    );
    return result.isEmpty ? null : FleetDocument.fromMap(result.first);
  }

  Future<List<FleetDocument>> getCurrentComplianceDocuments(
    int driverId,
  ) async {
    final db = await _database.database();
    final result = await db.query(
      tableName,
      where: 'driverId = ? AND isArchived = 0',
      whereArgs: [driverId],
      orderBy: 'lastUpdated DESC',
    );
    return result.map(FleetDocument.fromMap).toList();
  }

  Future<List<FleetDocument>> getComplianceDocumentHistory(
    int driverId,
    DocumentCategory category,
  ) async {
    final db = await _database.database();
    final result = await db.query(
      tableName,
      where: 'driverId = ? AND category = ?',
      whereArgs: [driverId, category.name],
      orderBy: 'lastUpdated DESC',
    );
    return result.map(FleetDocument.fromMap).toList();
  }

  Future<List<FleetDocument>> getArchivedComplianceDocuments(
    int driverId,
  ) async {
    final db = await _database.database();
    final result = await db.query(
      tableName,
      where: 'driverId = ? AND isArchived = 1',
      whereArgs: [driverId],
      orderBy: 'archivedAt DESC, lastUpdated DESC',
    );
    return result.map(FleetDocument.fromMap).toList();
  }

  /// Inserts replacement evidence before archiving the former current row.
  /// Callers must copy the file successfully before invoking this method.
  Future<int> replaceCurrentComplianceDocument(
    FleetDocument document,
  ) async {
    final driverId = document.driverId;
    if (driverId == null) {
      throw ArgumentError.value(document, 'document', 'Compliance evidence requires a driver ID.');
    }
    final db = await _database.database();
    return db.transaction((txn) async {
      final newId = await txn.insert(tableName, document.toMap());
      await txn.update(
        tableName,
        {
          'isArchived': 1,
          'archivedAt': DateTime.now().toIso8601String(),
          'replacedByDocumentId': newId,
        },
        where: 'driverId = ? AND category = ? AND isArchived = 0 AND id != ?',
        whereArgs: [driverId, document.category.name, newId],
      );
      return newId;
    });
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
