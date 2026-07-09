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
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Version 2 - Vehicles table
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

        // Version 3 - Link inspections to vehicles
        if (oldVersion < 3) {
          await db.execute("""
            ALTER TABLE inspections
            ADD COLUMN vehicleId INTEGER
          """);
        }

        // Version 4 - Inspection checklist results
        if (oldVersion < 4) {
          await db.execute("""
            CREATE TABLE IF NOT EXISTS inspection_results(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              inspectionNumber TEXT NOT NULL,
              itemId TEXT NOT NULL,
              title TEXT NOT NULL,
              category TEXT NOT NULL,
              status TEXT NOT NULL,
              notes TEXT
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
        vehicleId INTEGER,
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

    await db.execute("""
      CREATE TABLE inspection_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionNumber TEXT NOT NULL,
        itemId TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
      )
    """);
  }
}