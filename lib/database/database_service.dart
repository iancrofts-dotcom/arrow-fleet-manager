import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();

    _database = await openDatabase(
      join(dbPath, "arrow_fleet.db"),
      version: 1,
      onCreate: (db, version) async {
        await db.execute("""
          CREATE TABLE inspections(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            registration TEXT,
            driver TEXT,
            mileage TEXT,
            inspector TEXT,
            comments TEXT,
            inspectionDate TEXT
          )
        """);
      },
    );

    return _database!;
  }

  static Future<void> saveInspection({
    required String registration,
    required String driver,
    required String mileage,
    required String inspector,
    required String comments,
  }) async {

    final db = await database;

    await db.insert("inspections", {
      "registration": registration,
      "driver": driver,
      "mileage": mileage,
      "inspector": inspector,
      "comments": comments,
      "inspectionDate": DateTime.now().toIso8601String(),
    });
  }
}