import '../features/vehicles/models/vehicle.dart';
import 'database_service.dart';

class VehicleRepository {
  final DatabaseService databaseService;

  VehicleRepository({
    required this.databaseService,
  });

Future<int> getVehicleCount() async {
  final db = await databaseService.database.database();

  final result = await db.rawQuery(
    'SELECT COUNT(*) AS total FROM vehicles',
  );

  return (result.first['total'] as int?) ?? 0;
}

  Future<void> addVehicle(Vehicle vehicle) async {
    final db = await databaseService.database.database();

    await db.insert(
      'vehicles',
      vehicle.toMap(),
    );
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await databaseService.database.database();

    final maps = await db.query(
      'vehicles',
      orderBy: 'fleetNumber',
    );

    return maps
        .map((e) => Vehicle.fromMap(e))
        .toList();
  }

  Future<void> deleteVehicle(int id) async {
    final db = await databaseService.database.database();

    await db.delete(
      'vehicles',
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await databaseService.database.database();

    await db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id=?',
      whereArgs: [vehicle.id],
    );
  }
}