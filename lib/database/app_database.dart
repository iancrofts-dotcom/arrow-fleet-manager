import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _database;

  Future<Database> database() async {
    if (_database != null) return _database!;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'arrow_fleet.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("""
            CREATE TABLE IF NOT EXISTS vehicles(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              registration TEXT NOT NULL,
              fleetNumber TEXT NOT NULL,
              make TEXT,
              model TEXT,
              year INTEGER,
              vin TEXT,
              motExpiry TEXT,
              serviceDue TEXT,
              active INTEGER DEFAULT 1
            )
          """);
        }
      },
    );

    return _database!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute("""
      CREATE TABLE inspections(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionNumber TEXT,
        inspectionDate TEXT,
        registration TEXT,
        driver TEXT,
        inspector TEXT,
        mileage INTEGER,
        comments TEXT
      )
    """);

    await db.execute("""
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        registration TEXT NOT NULL,
        fleetNumber TEXT NOT NULL,
        make TEXT,
        model TEXT,
        year INTEGER,
        vin TEXT,
        motExpiry TEXT,
        serviceDue TEXT,
        active INTEGER DEFAULT 1
      )
    """);
  }
}