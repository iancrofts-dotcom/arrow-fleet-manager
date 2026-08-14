import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../models/inspection_item.dart';

class InspectionResultsRepository {
  final AppDatabase appDatabase;

  InspectionResultsRepository({
    required this.appDatabase,
  });

  Future<Database> get _db async =>
      await appDatabase.database();

  Future<void> saveItems({
    required String inspectionNumber,
    required List<InspectionItem> items,
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _db;

    final batch = db.batch();

    for (final item in items) {
      batch.insert(
        'inspection_results',
        {
          'inspectionNumber': inspectionNumber,
          'itemId': item.id,
          'title': item.title,
          'category': item.category,
          'status': item.status.name,
          'notes': item.notes,
          'photoPath': item.photoPath,
        },
        conflictAlgorithm:
            ConflictAlgorithm.replace,
      );
    }

    await batch.commit(
      noResult: true,
    );
  }

  Future<List<InspectionItem>> getItems(
    String inspectionNumber,
  ) async {
    final db = await _db;

    final results = await db.query(
      'inspection_results',
      where: 'inspectionNumber = ?',
      whereArgs: [inspectionNumber],
      orderBy: 'category,title',
    );

    return results.map((row) {
      return InspectionItem(
        id: row['itemId'] as String,
        title: row['title'] as String,
        category: row['category'] as String,
        status: InspectionStatus.values.firstWhere(
          (e) => e.name == row['status'],
        ),
        notes: row['notes'] as String? ?? '',
        photoPath: row['photoPath'] as String?,
      );
    }).toList();
  }  Future<List<InspectionItem>> getFailedItems(
    String inspectionNumber,
  ) async {
    final db = await _db;

    final results = await db.query(
      'inspection_results',
      where: 'inspectionNumber = ? AND status = ?',
      whereArgs: [
        inspectionNumber,
        InspectionStatus.fail.name,
      ],
      orderBy: 'category,title',
    );

    return results.map((row) {
      return InspectionItem(
        id: row['itemId'] as String,
        title: row['title'] as String,
        category: row['category'] as String,
        status: InspectionStatus.values.firstWhere(
          (e) => e.name == row['status'],
        ),
        notes: row['notes'] as String? ?? '',
        photoPath: row['photoPath'] as String?,
      );
    }).toList();
  }

  Future<void> deleteInspectionResults(
    String inspectionNumber,
  ) async {
    final db = await _db;

    await db.delete(
      'inspection_results',
      where: 'inspectionNumber = ?',
      whereArgs: [inspectionNumber],
    );
  }
}
