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

  Future<WorkshopInspection?> getInspectionByNumber(
    String inspectionNumber,
  ) async {
    final db = await _db;

    final result = await db.query(
      _table,
      where: 'inspectionNumber = ?',
      whereArgs: [inspectionNumber],
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
        WHERE status IN (?, ?, ?)
        ''',
        [
          'draft',
          'inProgress',
          'awaitingRepair',
        ],
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
        ['completed'],
      ),
    );

    return result ?? 0;
  }

Future<int> getCriticalFailureCount() async {
  final db = await _db;

  final result = Sqflite.firstIntValue(
    await db.rawQuery(
      '''
      SELECT COUNT(*)
      FROM workshop_inspection_items
      WHERE status = ?
      ''',
      ['fail'],
    ),
  );

  return result ?? 0;
}

Future<int> getRepairRequiredCount() async {
  final db = await _db;

  final result = Sqflite.firstIntValue(
    await db.rawQuery(
      '''
      SELECT COUNT(*)
      FROM workshop_repair_jobs
      WHERE status != ?
      AND status != ?
      ''',
      [
        'completed',
        'cancelled',
      ],
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


  /// Returns every repair job in the workshop, regardless of inspection.
  /// Jobs are returned newest first.
  Future<List<RepairJob>> getAllRepairJobs() async {
    final db = await _db;

    final result = await db.query(
      'workshop_repair_jobs',
      orderBy: 'createdAt DESC',
    );

    return result
        .map((map) => RepairJob.fromMap(map))
        .toList();
  }

  /// Returns repair jobs assigned to a specific technician user ID.
  Future<List<RepairJob>> getRepairJobsForTechnician(
    String technicianId,
  ) async {
    final db = await _db;

    final result = await db.query(
      'workshop_repair_jobs',
      where: 'technicianId = ?',
      whereArgs: [technicianId],
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

    final nonCancelledJobs = jobs.where(
      (job) => job.status != RepairJobStatus.cancelled,
    );

    final allCompleted = nonCancelledJobs.every(
      (job) => job.status == RepairJobStatus.completed,
    );

    if (allCompleted) {
      return RepairCompletionStatus.complete;
    }

    return RepairCompletionStatus.outstanding;
  }

  /// Completes an inspection once all of its non-cancelled repair jobs have
  /// been resolved. Final manager sign-off remains a separate action.
  Future<bool> completeInspectionWhenRepairsResolved(
    int inspectionId,
  ) async {
    final repairStatus = await getRepairCompletionStatus(inspectionId);

    if (repairStatus == RepairCompletionStatus.outstanding) {
      return false;
    }

    final inspection = await getInspection(inspectionId);

    if (inspection == null ||
        inspection.status != WorkshopInspectionStatus.awaitingRepair) {
      return false;
    }

    final now = DateTime.now();
    await updateInspection(
      inspection.copyWith(
        status: WorkshopInspectionStatus.completed,
        dateCompleted: inspection.dateCompleted ?? now,
        updatedAt: now,
      ),
    );

    return true;
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
