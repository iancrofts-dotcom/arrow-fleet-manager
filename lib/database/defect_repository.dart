import '../features/defects/models/defect.dart';
import 'database_service.dart';

class DefectRepository {
  final DatabaseService databaseService;

  DefectRepository({
    required this.databaseService,
  });

  Future<void> saveDefect(Defect defect) async {
    final db = await databaseService.database.database();

    await db.insert(
      'defects',
      defect.toMap(),
    );
  }

  Future<List<Defect>> getDefects() async {
    final db = await databaseService.database.database();

    final maps = await db.query(
      'defects',
      orderBy: 'reportedDate DESC',
    );

    return maps
        .map((map) => Defect.fromMap(map))
        .toList();
  }

  Future<List<Defect>> getVehicleDefects(int vehicleId) async {
    final db = await databaseService.database.database();

    final maps = await db.query(
      'defects',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'reportedDate DESC',
    );

    return maps
        .map((map) => Defect.fromMap(map))
        .toList();
  }

  Future<List<Defect>> getOpenDefects() async {
    final db = await databaseService.database.database();

    final maps = await db.query(
      'defects',
      where: 'repaired = ?',
      whereArgs: [0],
      orderBy: 'reportedDate DESC',
    );

    return maps
        .map((map) => Defect.fromMap(map))
        .toList();
  }

  Future<void> markRepaired(int defectId) async {
    final db = await databaseService.database.database();

    await db.update(
      'defects',
      {
        'repaired': 1,
      },
      where: 'id = ?',
      whereArgs: [defectId],
    );
  }

  Future<int> getOpenDefectCount() async {
    final db = await databaseService.database.database();

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM defects
      WHERE repaired = 0
      ''',
    );

    return (result.first['total'] as int?) ?? 0;
  }
}