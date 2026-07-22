import '../../../database/app_database.dart';

class FleetDashboardRepository {
  FleetDashboardRepository._();

  static final FleetDashboardRepository instance =
      FleetDashboardRepository._();

  final AppDatabase _database = AppDatabase();

  Future<int> getVehicleCount() async {
    final db = await _database.database();

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM vehicles',
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getActiveVehicleCount() async {
    final db = await _database.database();

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM vehicles WHERE active = 1',
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getDriverCount() async {
    final db = await _database.database();

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM drivers',
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getActiveDriverCount() async {
    final db = await _database.database();

    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM drivers WHERE active = 1',
    );

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getAssignedDrivers() async {
    final db = await _database.database();

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM driver_assignments
      WHERE active = 1
    ''');

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getAvailableDrivers() async {
    final total = await getDriverCount();
    final assigned = await getAssignedDrivers();

    return total - assigned;
  }

  Future<int> getAssignedVehicles() async {
    final db = await _database.database();

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM driver_assignments
      WHERE active = 1
    ''');

    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getUnassignedVehicles() async {
    final total = await getVehicleCount();
    final assigned = await getAssignedVehicles();

    return total - assigned;
  }



  Future<double> getFleetHealth() async {
    final total = await getVehicleCount();

    if (total == 0) {
      return 0;
    }

    final active = await getActiveVehicleCount();

    return (active / total) * 100;
  }
}