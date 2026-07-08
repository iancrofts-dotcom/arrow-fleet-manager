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
      {
        'inspectionNumber': inspection.inspectionNumber,
        'inspectionDate': inspection.inspectionDate.toIso8601String(),
        'registration': inspection.registration,
        'driver': inspection.driver,
        'inspector': inspection.inspector,
        'mileage': inspection.mileage,
        'comments': inspection.comments,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getInspections() async {
    final db = await databaseService.database.database();

    return await db.query(
      'inspections',
      orderBy: 'inspectionDate DESC',
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
    // Placeholder until defect records are stored.
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
}