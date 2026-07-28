import 'package:sqflite/sqflite.dart';

import '../../../database/database_service.dart';
import '../models/repair.dart';
import '../models/workshop_summary.dart';
import '../models/repair_trend.dart';

class RepairRepository {
  Future<Database> get _db async =>
      await DatabaseService()
          .database
          .database();

  Future<int> saveRepair(
    Repair repair,
  ) async {
    final db = await _db;

    return await db.insert(
      'repairs',
      repair.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<int> updateRepair(
    Repair repair,
  ) async {
    final db = await _db;

    return await db.update(
      'repairs',
      repair.toMap(),
      where: 'id = ?',
      whereArgs: [repair.id],
    );
  }

  Future<int> deleteRepair(
    int id,
  ) async {
    final db = await _db;

    return await db.delete(
      'repairs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Repair?> getRepair(
    int id,
  ) async {
    final db = await _db;

    final result = await db.query(
      'repairs',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Repair.fromMap(
      result.first,
    );
  }

  Future<List<Repair>> getRepairs() async {
    final db = await _db;

    final result = await db.query(
      'repairs',
      orderBy: 'dateRaised DESC',
    );

    return result
        .map(
          (e) => Repair.fromMap(e),
        )
        .toList();
  }  Future<List<Repair>> getOpenRepairs() async {
    final db = await _db;

    final result = await db.query(
      'repairs',
      where: 'status != ?',
      whereArgs: ['Completed'],
      orderBy: 'dateRaised DESC',
    );

    return result
        .map(
          (e) => Repair.fromMap(e),
        )
        .toList();
  }

  Future<List<Repair>> getCompletedRepairs() async {
    final db = await _db;

    final result = await db.query(
      'repairs',
      where: 'status = ?',
      whereArgs: ['Completed'],
      orderBy: 'completedDate DESC',
    );

    return result
        .map(
          (e) => Repair.fromMap(e),
        )
        .toList();
  }
  /// Returns the total number of open repairs.
Future<int> getOpenRepairCount() async {
  final repairs = await getOpenRepairs();
  return repairs.length;
}

/// Returns the total number of high or critical priority repairs.
Future<int> getHighPriorityCount() async {
  final repairs = await getRepairs();

  return repairs.where((repair) {
    final priority = repair.priority.toLowerCase();
    return priority == 'high' || priority == 'critical';
  }).length;
}

/// Returns the number of overdue repairs.
Future<int> getOverdueRepairCount() async {
  final now = DateTime.now();

  final repairs = await getOpenRepairs();

  return repairs.where((repair) {
    if (repair.dueDate == null) {
      return false;
    }

    return repair.dueDate!.isBefore(now);
  }).length;
}

/// Returns the number of repairs completed in the last 7 days.
Future<int> getCompletedThisWeekCount() async {
  final weekAgo = DateTime.now().subtract(
    const Duration(days: 7),
  );

  final repairs = await getCompletedRepairs();

  return repairs.where((repair) {
    return repair.completedDate != null &&
        repair.completedDate!.isAfter(weekAgo);
  }).length;
}
Future<WorkshopSummary> getWorkshopSummary() async {
  final openRepairs =
      await getOpenRepairCount();

  final highPriority =
      await getHighPriorityCount();

  final overdueRepairs =
      await getOverdueRepairCount();

  final completedThisWeek =
      await getCompletedThisWeekCount();

  return WorkshopSummary(
    openRepairs: openRepairs,
    highPriority: highPriority,
    overdueRepairs: overdueRepairs,
    completedThisWeek: completedThisWeek,
  );
}

Future<List<RepairTrend>> getWeeklyRepairTrends() async {
  final repairs = await getRepairs();

  final now = DateTime.now();
  final trends = <RepairTrend>[];

  for (int i = 5; i >= 0; i--) {
    final weekStart = now.subtract(
      Duration(days: (i + 1) * 7),
    );

    final weekEnd = now.subtract(
      Duration(days: i * 7),
    );

    final opened = repairs.where((repair) {
      return repair.dateRaised.isAfter(weekStart) &&
          repair.dateRaised.isBefore(weekEnd);
    }).length;

    final completed = repairs.where((repair) {
      return repair.status == 'Completed' &&
          repair.completedDate != null &&
          repair.completedDate!.isAfter(weekStart) &&
          repair.completedDate!.isBefore(weekEnd);
    }).length;

    trends.add(
      RepairTrend(
        period: 'W${6 - i}',
        opened: opened,
        completed: completed,
      ),
    );
  }

  return trends;
}

}