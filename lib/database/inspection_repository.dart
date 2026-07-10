import '../features/inspections/models/inspection.dart';
import 'database_service.dart';

class InspectionRepository {
  final DatabaseService databaseService;

  InspectionRepository({
    required this.databaseService,
  });

  Future<void> saveInspection(Inspection inspection) async {
    final db = await databaseService.database.database();

    await db.insert(
      'inspections',
      inspection.toMap(),
    );
  }

  Future<List<Inspection>> getInspections() async {
    final db = await databaseService.database.database();

    final maps = await db.query(
      'inspections',
      orderBy: 'inspectionDate DESC',
    );

    return maps
        .map((map) => Inspection.fromMap(map))
        .toList();
  }

  Future<Inspection?> getInspectionById(int id) async {
    final db = await databaseService.database.database();

    final maps = await db.query(
      'inspections',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Inspection.fromMap(maps.first);
  }

  Future<int> deleteInspection(int id) async {
    final db = await databaseService.database.database();

    return db.delete(
      'inspections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getInspectionCount() async {
    final db = await databaseService.database.database();

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM inspections',
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTodayInspectionCount() async {
    final db = await databaseService.database.database();

    final today = DateTime.now().toIso8601String().split('T').first;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM inspections
      WHERE inspectionDate LIKE ?
      ''',
      ['$today%'],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getOpenDefectCount() async {
    // Placeholder until defects are implemented.
    return 0;
  }

  Future<double> getPassRate() async {
    final total = await getInspectionCount();

    if (total == 0) {
      return 100.0;
    }

    final defects = await getOpenDefectCount();

    return ((total - defects) / total) * 100;
  }

Future<List<Inspection>> getRecentInspections({
  int limit = 5,
}) async {
  final db = await databaseService.database.database();

  final maps = await db.query(
    'inspections',
    orderBy: 'inspectionDate DESC',
    limit: limit,
  );

  return maps
      .map((e) => Inspection.fromMap(e))
      .toList();
}

}