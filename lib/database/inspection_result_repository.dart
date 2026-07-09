import '../features/inspections/models/inspection_result.dart';
import 'database_service.dart';

class InspectionResultRepository {
  final DatabaseService databaseService;

  InspectionResultRepository({
    required this.databaseService,
  });

  Future<void> saveResults(
    List<InspectionResult> results,
  ) async {
    final db = await databaseService.database.database();

    final batch = db.batch();

    for (final result in results) {
      batch.insert(
        'inspection_results',
        result.toMap(),
      );
    }

    await batch.commit(
      noResult: true,
    );
  }

  Future<List<InspectionResult>> getResults(
    String inspectionNumber,
  ) async {
    final db = await databaseService.database.database();

    final maps = await db.query(
      'inspection_results',
      where: 'inspectionNumber = ?',
      whereArgs: [inspectionNumber],
      orderBy: 'category, title',
    );

    return maps
        .map(InspectionResult.fromMap)
        .toList();
  }

  Future<void> deleteResults(
    String inspectionNumber,
  ) async {
    final db = await databaseService.database.database();

    await db.delete(
      'inspection_results',
      where: 'inspectionNumber = ?',
      whereArgs: [inspectionNumber],
    );
  }
}