// ============================================================================
// Arrow Fleet Manager Workshop Database Baseline
// Generated from the uploaded app_database.dart.
// ============================================================================
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Database? _database;

  Future<Database> database() async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'arrow_fleet.db');

    _database = await openDatabase(
      path,
      version: 16,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {

        if (oldVersion < 2) {
          await db.execute('''
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
          ''');
        }

        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE inspections ADD COLUMN vehicleId INTEGER',
          );
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS inspection_results(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              inspectionNumber TEXT NOT NULL,
              itemId TEXT NOT NULL,
              title TEXT NOT NULL,
              category TEXT NOT NULL,
              status TEXT NOT NULL,
              notes TEXT,
              photoPath TEXT
            )
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS drivers(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              licence_number TEXT NOT NULL,
              licence_expiry INTEGER,
              phone TEXT,
              email TEXT,
              username TEXT,
              active INTEGER DEFAULT 1
            )
          ''');
        }

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS driver_assignments(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              driver_id INTEGER NOT NULL,
              vehicle_id INTEGER NOT NULL,
              assigned_from INTEGER NOT NULL,
              assigned_to INTEGER,
              active INTEGER DEFAULT 1
            )
          ''');
        }

        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS driver_compliance(
              driverId INTEGER PRIMARY KEY,
              licenceExpiry TEXT NOT NULL,
              cpcExpiry TEXT NOT NULL,
              medicalExpiry TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS maintenance_records(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              vehicle_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              due_date INTEGER NOT NULL,
              completed_date INTEGER,
              estimated_cost REAL NOT NULL,
              actual_cost REAL,
              completed INTEGER DEFAULT 0
            )
          ''');
        }

        if (oldVersion < 9) {
          await db.execute(
            'ALTER TABLE driver_compliance ADD COLUMN lastUpdated TEXT',
          );
        }

        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS fleet_documents(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              category TEXT NOT NULL,
              filePath TEXT NOT NULL,
              issueDate TEXT NOT NULL,
              expiryDate TEXT NOT NULL,
              lastUpdated TEXT NOT NULL,
              notes TEXT,
              driverId INTEGER,
              vehicleId INTEGER
            )
          ''');
        }

        if (oldVersion < 11) {
          await db.execute(
            'ALTER TABLE drivers ADD COLUMN username TEXT',
          );
        }

        if (oldVersion < 12) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users(
              id TEXT PRIMARY KEY,
              username TEXT NOT NULL UNIQUE,
              password_hash TEXT NOT NULL,
              role TEXT NOT NULL,
              driver_id INTEGER,
              is_active INTEGER NOT NULL DEFAULT 1,
              FOREIGN KEY(driver_id)
                REFERENCES drivers(id)
                ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 13) {
          await db.execute(
            'ALTER TABLE inspections ADD COLUMN fuelLevel TEXT DEFAULT "Full"',
          );

          await db.execute(
            'ALTER TABLE inspections ADD COLUMN overallResult TEXT DEFAULT "Pending"',
          );

          await db.execute(
            'ALTER TABLE inspections ADD COLUMN status TEXT DEFAULT "New"',
          );
        }

        // Version 14 - Inspection Evidence
        if (oldVersion < 14) {
          await db.execute(
            'ALTER TABLE inspection_results ADD COLUMN photoPath TEXT',
          );
        }

        // Version 15 - Workshop Repairs
        if (oldVersion < 15) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS repairs(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              repairNumber TEXT NOT NULL,
              inspectionNumber TEXT NOT NULL,
              registration TEXT NOT NULL,
              driver TEXT NOT NULL,
              defect TEXT NOT NULL,
              defectNotes TEXT,
              photoPath TEXT,
              mechanic TEXT NOT NULL,
              priority TEXT NOT NULL,
              status TEXT NOT NULL,
              dateRaised TEXT NOT NULL,
              dueDate TEXT,
              completedDate TEXT,
              repairNotes TEXT
            )
          ''');
        }

        // ============================================================================
// Version 16 - Workshop Inspections
// ============================================================================

if (oldVersion < 16) {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS workshop_inspections(
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      inspectionNumber TEXT NOT NULL,

      vehicleId INTEGER NOT NULL,
      registration TEXT NOT NULL,
      fleetNumber TEXT NOT NULL,

      technicianId INTEGER,
      technicianName TEXT NOT NULL,
      workshopManager TEXT,

      inspectionType TEXT NOT NULL,
      status TEXT NOT NULL,
      vehicleStatus TEXT NOT NULL,

      dateStarted TEXT NOT NULL,
      dateCompleted TEXT,

      mileage INTEGER NOT NULL,

      overallResult TEXT NOT NULL,
      inspectionScore INTEGER NOT NULL DEFAULT 0,

      criticalFailures INTEGER NOT NULL DEFAULT 0,
      advisories INTEGER NOT NULL DEFAULT 0,
      repairsRequired INTEGER NOT NULL DEFAULT 0,

      labourHours REAL NOT NULL DEFAULT 0,
      totalCost REAL NOT NULL DEFAULT 0,

      notes TEXT,

      technicianSignature TEXT,
      managerSignature TEXT,

      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''');
}

await db.execute('''
CREATE TABLE IF NOT EXISTS workshop_inspection_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  inspectionId INTEGER NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  status TEXT NOT NULL,
  mandatory INTEGER NOT NULL DEFAULT 1,
  repairRequired INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  photoCount INTEGER NOT NULL DEFAULT 0,
  displayOrder INTEGER NOT NULL,
  FOREIGN KEY(inspectionId)
    REFERENCES workshop_inspections(id)
    ON DELETE CASCADE
)
''');

await db.execute('''
CREATE TABLE IF NOT EXISTS workshop_repair_jobs(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  inspectionId INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL,
  status TEXT NOT NULL,
  mechanic TEXT,
  estimatedHours REAL DEFAULT 0,
  actualHours REAL DEFAULT 0,
  estimatedCost REAL DEFAULT 0,
  actualCost REAL DEFAULT 0,
  createdAt TEXT NOT NULL,
  completedAt TEXT,
  FOREIGN KEY(inspectionId)
    REFERENCES workshop_inspections(id)
    ON DELETE CASCADE
)
''');

await db.execute('''
CREATE TABLE IF NOT EXISTS inspection_templates(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  vehicleType TEXT NOT NULL,
  isDefault INTEGER NOT NULL DEFAULT 0,
  isActive INTEGER NOT NULL DEFAULT 1,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
''');

await db.execute('''
CREATE TABLE IF NOT EXISTS inspection_template_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  templateId INTEGER NOT NULL,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  displayOrder INTEGER NOT NULL,
  mandatory INTEGER NOT NULL DEFAULT 1,
  criticalSafetyItem INTEGER NOT NULL DEFAULT 0,
  autoCreateRepair INTEGER NOT NULL DEFAULT 1,
  photoRequiredOnFail INTEGER NOT NULL DEFAULT 0,
  allowNotes INTEGER NOT NULL DEFAULT 1,
  defaultStatus TEXT NOT NULL,
  isActive INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY(templateId)
    REFERENCES inspection_templates(id)
    ON DELETE CASCADE
)
''');

      },
    );

    return _database!;
  }

  Future<void> _createTables(Database db) async {
        await db.execute('''
      CREATE TABLE inspections(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionNumber TEXT,
        inspectionDate TEXT,
        vehicleId INTEGER,
        registration TEXT,
        driver TEXT,
        mileage INTEGER,
        fuelLevel TEXT,
        comments TEXT,
        overallResult TEXT,
        status TEXT
      )
    ''');

    await db.execute('''
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
    ''');

    await db.execute('''
      CREATE TABLE inspection_results(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionNumber TEXT NOT NULL,
        itemId TEXT NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        photoPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE drivers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        licence_number TEXT NOT NULL,
        licence_expiry INTEGER,
        phone TEXT,
        email TEXT,
        username TEXT,
        active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        driver_id INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(driver_id)
          REFERENCES drivers(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE driver_assignments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        driver_id INTEGER NOT NULL,
        vehicle_id INTEGER NOT NULL,
        assigned_from INTEGER NOT NULL,
        assigned_to INTEGER,
        active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE driver_compliance(
        driverId INTEGER PRIMARY KEY,
        licenceExpiry TEXT NOT NULL,
        cpcExpiry TEXT NOT NULL,
        medicalExpiry TEXT NOT NULL,
        lastUpdated TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        due_date INTEGER NOT NULL,
        completed_date INTEGER,
        estimated_cost REAL NOT NULL,
        actual_cost REAL,
        completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE fleet_documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        filePath TEXT NOT NULL,
        issueDate TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        lastUpdated TEXT NOT NULL,
        notes TEXT,
        driverId INTEGER,
        vehicleId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE repairs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        repairNumber TEXT NOT NULL,
        inspectionNumber TEXT NOT NULL,
        registration TEXT NOT NULL,
        driver TEXT NOT NULL,
        defect TEXT NOT NULL,
        defectNotes TEXT,
        photoPath TEXT,
        mechanic TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        dateRaised TEXT NOT NULL,
        dueDate TEXT,
        completedDate TEXT,
        repairNotes TEXT
      )
    ''');

  await db.execute('''
  CREATE TABLE workshop_inspections(
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    inspectionNumber TEXT NOT NULL,

    vehicleId INTEGER NOT NULL,
    registration TEXT NOT NULL,
    fleetNumber TEXT NOT NULL,

    technicianId INTEGER,
    technicianName TEXT NOT NULL,
    workshopManager TEXT,

    inspectionType TEXT NOT NULL,
    status TEXT NOT NULL,
    vehicleStatus TEXT NOT NULL,

    dateStarted TEXT NOT NULL,
    dateCompleted TEXT,

    mileage INTEGER NOT NULL,

    overallResult TEXT NOT NULL,
    inspectionScore INTEGER NOT NULL DEFAULT 0,

    criticalFailures INTEGER NOT NULL DEFAULT 0,
    advisories INTEGER NOT NULL DEFAULT 0,
    repairsRequired INTEGER NOT NULL DEFAULT 0,

    labourHours REAL NOT NULL DEFAULT 0,
    totalCost REAL NOT NULL DEFAULT 0,

    notes TEXT,

    technicianSignature TEXT,
    managerSignature TEXT,

    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
  )
''');

  }
}