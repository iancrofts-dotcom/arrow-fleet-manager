import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _databaseName = 'arrow_fleet.db';
  static const _databaseVersion = 1;

  static Database? _database;

  Future<Database> database() async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, _databaseName);

    _database = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
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
    ''');
  }
}