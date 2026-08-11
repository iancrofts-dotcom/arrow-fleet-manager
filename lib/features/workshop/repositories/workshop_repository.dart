import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../models/inspection_item.dart';
import '../models/repair_job.dart';
import '../models/workshop_inspection.dart';

/// ============================================================================
/// WORKSHOP REPOSITORY
/// ============================================================================
///
/// Handles all database operations for workshop inspections.
/// Additional methods (photos, templates and dashboard statistics)
/// will be added in later steps.
/// ============================================================================

enum RepairCompletionStatus {
  noRepairs,
  outstanding,
  complete,
}

class WorkshopRepository {
  WorkshopRepository({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  static const String _table = 'workshop_inspections';

  Future<Database> get _db async => await _database.database();

  // ==========================================================================
  // CREATE
  // ==========================================================================

  Future<int> createInspection(
    WorkshopInspection inspection,
  ) async {
    final db = await _db;

    return db.insert(
      _table,
      inspection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================================================
  // READ
  // ==========================================================================

  Future<WorkshopInspection?> getInspection(int id) async {
    final db = await _db;

    final result = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return WorkshopInspection.fromMap(result.first);
  }

  Future<List<WorkshopInspection>> getAllInspections() async {
    final db = await _db;

    final result = await db.query(
      _table,
      orderBy: 'createdAt DESC',
    );

    return result
        .map((map) => WorkshopInspection.fromMap(map))
        .toList();
  }

  // ==========================================================================
  // UPDATE
  // ==========================================================================

  Future<int> updateInspection(
    WorkshopInspection inspection,
  ) async {
    final db = await _db;

    return db.update(
      _table,
      inspection.toMap(),
      where: 'id = ?',
      whereArgs: [inspection.id],
    );
  }

  // ==========================================================================
  // DELETE
  // ==========================================================================

  Future<int> deleteInspection(int id) async {
    final db = await _db;

    return db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================================
  // EXISTS
  // ==========================================================================

  Future<bool> inspectionExists(int id) async {
    final inspection = await getInspection(id);
    return inspection != null;
  }

  // ==========================================================================
  // COUNT
  // ==========================================================================

  Future<int> getInspectionCount() async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $_table',
      ),
    );

    return result ?? 0;
  }

  Future<int> getOpenInspectionCount() async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM $_table
        WHERE status = ?
        ''',
        ['Open'],
      ),
    );

    return result ?? 0;
  }

  Future<int> getCompletedInspectionCount() async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COUNT(*)
        FROM $_table
        WHERE status = ?
        ''',
        ['Completed'],
      ),
    );

    return result ?? 0;
  }

  Future<int> getCriticalFailureCount() async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COALESCE(SUM(criticalFailures), 0)
        FROM $_table
        ''',
      ),
    );

    return result ?? 0;
  }

  Future<int> getRepairRequiredCount() async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        '''
        SELECT COALESCE(SUM(repairsRequired), 0)
        FROM $_table
        ''',
      ),
    );

    return result ?? 0;
  }

  // ==========================================================================
  // INSPECTION ITEMS
  // ==========================================================================

  Future<int> addInspectionItem(
    InspectionItem item,
  ) async {
    final db = await _db;

    return db.insert(
      'workshop_inspection_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addInspectionItems(
    List<InspectionItem> items,
  ) async {
    final db = await _db;

    final batch = db.batch();

    for (final item in items) {
      batch.insert(
        'workshop_inspection_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(
      noResult: true,
    );
  }

  Future<List<InspectionItem>> getInspectionItems(
    int inspectionId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'workshop_inspection_items',
      where: 'inspectionId = ?',
      whereArgs: [inspectionId],
      orderBy: 'displayOrder ASC',
    );

    return result
        .map((map) => InspectionItem.fromMap(map))
        .toList();
  }

  Future<int> updateInspectionItem(
    InspectionItem item,
  ) async {
    final db = await _db;

    return db.update(
      'workshop_inspection_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteInspectionItem(int id) async {
    final db = await _db;

    return db.delete(
      'workshop_inspection_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInspectionItems(
    int inspectionId,
  ) async {
    final db = await _db;

    return db.delete(
      'workshop_inspection_items',
      where: 'inspectionId = ?',
      whereArgs: [inspectionId],
    );
  }

  // ==========================================================================
  // REPAIR JOBS
  // ==========================================================================

  Future<int> createRepairJob(
    RepairJob job,
  ) async {
    final db = await _db;

    return db.insert(
      'workshop_repair_jobs',
      job.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RepairJob>> getRepairJobs(
    int inspectionId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'workshop_repair_jobs',
      where: 'inspectionId = ?',
      whereArgs: [inspectionId],
      orderBy: 'createdAt DESC',
    );

    return result
        .map((map) => RepairJob.fromMap(map))
        .toList();
  }

  Future<RepairJob?> getRepairJob(int id) async {
    final db = await _db;

    final result = await db.query(
      'workshop_repair_jobs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return RepairJob.fromMap(result.first);
  }

  Future<int> updateRepairJob(
    RepairJob job,
  ) async {
    final db = await _db;

    return db.update(
      'workshop_repair_jobs',
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }


  Future<RepairCompletionStatus> getRepairCompletionStatus(
    int inspectionId,
  ) async {
    final jobs = await getRepairJobs(inspectionId);

    if (jobs.isEmpty) {
      return RepairCompletionStatus.noRepairs;
    }

    final allCompleted = jobs.every(
      (job) => job.status == RepairJobStatus.completed,
    );

    if (allCompleted) {
      return RepairCompletionStatus.complete;
    }

    return RepairCompletionStatus.outstanding;
  }

  Future<int> deleteRepairJob(int id) async {
    final db = await _db;

    return db.delete(
      'workshop_repair_jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRepairJobs(
    int inspectionId,
  ) async {
    final db = await _db;

    return db.delete(
      'workshop_repair_jobs',
      where: 'inspectionId = ?',
      whereArgs: [inspectionId],
    );
  }
}