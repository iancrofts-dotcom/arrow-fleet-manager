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
      version: 10,
      onCreate: (db, version) async => await _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("""CREATE TABLE IF NOT EXISTS vehicles(id INTEGER PRIMARY KEY AUTOINCREMENT,registration TEXT NOT NULL,fleetNumber TEXT NOT NULL,make TEXT,model TEXT,year INTEGER,vin TEXT,motExpiry TEXT,serviceDue TEXT,active INTEGER DEFAULT 1)""");
        }
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE inspections ADD COLUMN vehicleId INTEGER");
        }
        if (oldVersion < 4) {
          await db.execute("""CREATE TABLE IF NOT EXISTS inspection_results(id INTEGER PRIMARY KEY AUTOINCREMENT,inspectionNumber TEXT NOT NULL,itemId TEXT NOT NULL,title TEXT NOT NULL,category TEXT NOT NULL,status TEXT NOT NULL,notes TEXT)""");
        }
        if (oldVersion < 5) {
          await db.execute("""CREATE TABLE IF NOT EXISTS drivers(id INTEGER PRIMARY KEY AUTOINCREMENT,first_name TEXT NOT NULL,last_name TEXT NOT NULL,licence_number TEXT NOT NULL,licence_expiry INTEGER,phone TEXT,email TEXT,active INTEGER DEFAULT 1)""");
        }
        if (oldVersion < 6) {
          await db.execute("""CREATE TABLE IF NOT EXISTS driver_assignments(id INTEGER PRIMARY KEY AUTOINCREMENT,driver_id INTEGER NOT NULL,vehicle_id INTEGER NOT NULL,assigned_from INTEGER NOT NULL,assigned_to INTEGER,active INTEGER DEFAULT 1)""");
        }
        if (oldVersion < 7) {
          await db.execute("""CREATE TABLE IF NOT EXISTS driver_compliance(driverId INTEGER PRIMARY KEY,licenceExpiry TEXT NOT NULL,cpcExpiry TEXT NOT NULL,medicalExpiry TEXT NOT NULL)""");
        }
        if (oldVersion < 8) {
          await db.execute("""CREATE TABLE IF NOT EXISTS maintenance_records(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL,title TEXT NOT NULL,description TEXT NOT NULL,due_date INTEGER NOT NULL,completed_date INTEGER,estimated_cost REAL NOT NULL,actual_cost REAL,completed INTEGER DEFAULT 0)""");
        }
        if (oldVersion < 9) {
          await db.execute("ALTER TABLE driver_compliance ADD COLUMN lastUpdated TEXT");
        }
        if (oldVersion < 10) {
          await db.execute("""CREATE TABLE IF NOT EXISTS fleet_documents(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,category TEXT NOT NULL,filePath TEXT NOT NULL,issueDate TEXT NOT NULL,expiryDate TEXT NOT NULL,lastUpdated TEXT NOT NULL,notes TEXT,driverId INTEGER,vehicleId INTEGER)""");
        }
      },
    );
    return _database!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute("""CREATE TABLE inspections(id INTEGER PRIMARY KEY AUTOINCREMENT,inspectionNumber TEXT,inspectionDate TEXT,vehicleId INTEGER,registration TEXT,driver TEXT,inspector TEXT,mileage INTEGER,comments TEXT)""");
    await db.execute("""CREATE TABLE vehicles(id INTEGER PRIMARY KEY AUTOINCREMENT,registration TEXT NOT NULL,fleetNumber TEXT NOT NULL,make TEXT,model TEXT,year INTEGER,vin TEXT,motExpiry TEXT,serviceDue TEXT,active INTEGER DEFAULT 1)""");
    await db.execute("""CREATE TABLE inspection_results(id INTEGER PRIMARY KEY AUTOINCREMENT,inspectionNumber TEXT NOT NULL,itemId TEXT NOT NULL,title TEXT NOT NULL,category TEXT NOT NULL,status TEXT NOT NULL,notes TEXT)""");
    await db.execute("""CREATE TABLE drivers(id INTEGER PRIMARY KEY AUTOINCREMENT,first_name TEXT NOT NULL,last_name TEXT NOT NULL,licence_number TEXT NOT NULL,licence_expiry INTEGER,phone TEXT,email TEXT,active INTEGER DEFAULT 1)""");
    await db.execute("""CREATE TABLE driver_assignments(id INTEGER PRIMARY KEY AUTOINCREMENT,driver_id INTEGER NOT NULL,vehicle_id INTEGER NOT NULL,assigned_from INTEGER NOT NULL,assigned_to INTEGER,active INTEGER DEFAULT 1)""");
    await db.execute("""CREATE TABLE driver_compliance(driverId INTEGER PRIMARY KEY,licenceExpiry TEXT NOT NULL,cpcExpiry TEXT NOT NULL,medicalExpiry TEXT NOT NULL,lastUpdated TEXT NOT NULL)""");
    await db.execute("""CREATE TABLE maintenance_records(id INTEGER PRIMARY KEY AUTOINCREMENT,vehicle_id INTEGER NOT NULL,title TEXT NOT NULL,description TEXT NOT NULL,due_date INTEGER NOT NULL,completed_date INTEGER,estimated_cost REAL NOT NULL,actual_cost REAL,completed INTEGER DEFAULT 0)""");
    await db.execute("""CREATE TABLE fleet_documents(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,category TEXT NOT NULL,filePath TEXT NOT NULL,issueDate TEXT NOT NULL,expiryDate TEXT NOT NULL,lastUpdated TEXT NOT NULL,notes TEXT,driverId INTEGER,vehicleId INTEGER)""");
  }
}
