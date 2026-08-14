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
      version: 21,
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

        // Version 16 - Workshop Inspections
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

        // Version 17 - Repair Job Model Alignment
        if (oldVersion < 17) {
          await db.transaction((txn) async {
            await txn.execute(
              'ALTER TABLE workshop_repair_jobs RENAME TO workshop_repair_jobs_v16',
            );

            await txn.execute('''
              CREATE TABLE workshop_repair_jobs(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                jobNumber TEXT NOT NULL,
                inspectionId INTEGER NOT NULL,
                inspectionItemId INTEGER,
                vehicleId INTEGER NOT NULL,
                vehicleRegistration TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                priority TEXT NOT NULL,
                status TEXT NOT NULL,
                technicianId INTEGER,
                technicianName TEXT NOT NULL DEFAULT '',
                partsRequired INTEGER NOT NULL DEFAULT 0,
                estimatedHours REAL NOT NULL DEFAULT 0,
                actualHours REAL NOT NULL DEFAULT 0,
                estimatedCost REAL NOT NULL DEFAULT 0,
                actualCost REAL NOT NULL DEFAULT 0,
                roadworthy INTEGER NOT NULL DEFAULT 0,
                createdAt TEXT NOT NULL,
                startedAt TEXT,
                completedAt TEXT,
                FOREIGN KEY(inspectionId)
                  REFERENCES workshop_inspections(id)
                  ON DELETE CASCADE
              )
            ''');

            await txn.execute('''
              INSERT INTO workshop_repair_jobs(
                id,
                jobNumber,
                inspectionId,
                inspectionItemId,
                vehicleId,
                vehicleRegistration,
                title,
                description,
                priority,
                status,
                technicianId,
                technicianName,
                partsRequired,
                estimatedHours,
                actualHours,
                estimatedCost,
                actualCost,
                roadworthy,
                createdAt,
                startedAt,
                completedAt
              )
              SELECT
                id,
                'LEGACY-' || id,
                inspectionId,
                NULL,
                (
                  SELECT vehicleId
                  FROM workshop_inspections
                  WHERE workshop_inspections.id = workshop_repair_jobs_v16.inspectionId
                ),
                COALESCE(
                  (
                    SELECT registration
                    FROM workshop_inspections
                    WHERE workshop_inspections.id = workshop_repair_jobs_v16.inspectionId
                  ),
                  ''
                ),
                title,
                COALESCE(description, ''),
                priority,
                status,
                NULL,
                COALESCE(mechanic, ''),
                0,
                COALESCE(estimatedHours, 0),
                COALESCE(actualHours, 0),
                COALESCE(estimatedCost, 0),
                COALESCE(actualCost, 0),
                0,
                createdAt,
                NULL,
                completedAt
              FROM workshop_repair_jobs_v16
            ''');

            await txn.execute('DROP TABLE workshop_repair_jobs_v16');
          });
        }

        // Version 18 - Workshop Inspection Photos
        if (oldVersion < 18) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS workshop_inspection_photos(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              inspectionId INTEGER NOT NULL,
              inspectionItemId INTEGER NOT NULL,
              filePath TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              FOREIGN KEY(inspectionId)
                REFERENCES workshop_inspections(id)
                ON DELETE CASCADE,
              FOREIGN KEY(inspectionItemId)
                REFERENCES workshop_inspection_items(id)
                ON DELETE CASCADE
            )
          ''');
        }

        // Version 19 - Driver Daily Workshop Inspection Link
        if (oldVersion < 19) {
          await db.execute(
            'ALTER TABLE workshop_inspections ADD COLUMN driverId INTEGER',
          );
          await db.execute(
            'ALTER TABLE workshop_inspections ADD COLUMN driverName TEXT',
          );
        }

        // Version 20 - Custom Workshop Inspection Templates
        if (oldVersion < 20) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS inspection_template_sections(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              templateId INTEGER NOT NULL,
              title TEXT NOT NULL,
              displayOrder INTEGER NOT NULL,
              FOREIGN KEY(templateId)
                REFERENCES inspection_templates(id)
                ON DELETE CASCADE
            )
          ''');
          await db.execute(
            'ALTER TABLE inspection_template_items ADD COLUMN sectionId INTEGER',
          );
          await db.execute(
            "ALTER TABLE inspection_template_items ADD COLUMN responseType TEXT NOT NULL DEFAULT 'passFailNotApplicable'",
          );
          await db.execute(
            "ALTER TABLE inspection_template_items ADD COLUMN repairPriority TEXT NOT NULL DEFAULT 'medium'",
          );
          await db.execute(
            "ALTER TABLE inspection_template_items ADD COLUMN roadworthyImpact TEXT NOT NULL DEFAULT 'none'",
          );
          await db.execute(
            'ALTER TABLE workshop_inspections ADD COLUMN templateId INTEGER',
          );
          await db.execute(
            'ALTER TABLE workshop_inspections ADD COLUMN templateName TEXT',
          );
          await db.execute(
            'ALTER TABLE workshop_inspection_items ADD COLUMN sectionTitle TEXT',
          );
          await db.execute(
            "ALTER TABLE workshop_inspection_items ADD COLUMN responseType TEXT NOT NULL DEFAULT 'passFailNotApplicable'",
          );
          await db.execute(
            'ALTER TABLE workshop_inspection_items ADD COLUMN responseValue TEXT',
          );
        }

        // Version 21 - Technician user IDs are text values, matching users.id.
        if (oldVersion < 21) {
          await _migrateTechnicianIdsToText(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _migrateTechnicianIdsToText(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');

    try {
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE workshop_inspections_v20_copy AS
          SELECT *, CAST(technicianId AS TEXT) AS technicianIdText
          FROM workshop_inspections
        ''');
        await txn.execute('''
          CREATE TABLE workshop_inspection_items_v20_copy AS
          SELECT * FROM workshop_inspection_items
        ''');
        await txn.execute('''
          CREATE TABLE workshop_inspection_photos_v20_copy AS
          SELECT * FROM workshop_inspection_photos
        ''');
        await txn.execute('''
          CREATE TABLE workshop_repair_jobs_v20_copy AS
          SELECT *, CAST(technicianId AS TEXT) AS technicianIdText
          FROM workshop_repair_jobs
        ''');

        await txn.execute('DROP TABLE workshop_inspection_photos');
        await txn.execute('DROP TABLE workshop_repair_jobs');
        await txn.execute('DROP TABLE workshop_inspection_items');
        await txn.execute('DROP TABLE workshop_inspections');

        await _createWorkshopInspectionTables(txn);

        await txn.execute('''
          INSERT INTO workshop_inspections(
            id, inspectionNumber, vehicleId, registration, fleetNumber,
            templateId, templateName, technicianId, technicianName, driverId,
            driverName, workshopManager, inspectionType, status, vehicleStatus,
            dateStarted, dateCompleted, mileage, overallResult, inspectionScore,
            criticalFailures, advisories, repairsRequired, labourHours, totalCost,
            notes, technicianSignature, managerSignature, createdAt, updatedAt
          )
          SELECT
            id, inspectionNumber, vehicleId, registration, fleetNumber,
            templateId, templateName, technicianIdText, technicianName, driverId,
            driverName, workshopManager, inspectionType, status, vehicleStatus,
            dateStarted, dateCompleted, mileage, overallResult, inspectionScore,
            criticalFailures, advisories, repairsRequired, labourHours, totalCost,
            notes, technicianSignature, managerSignature, createdAt, updatedAt
          FROM workshop_inspections_v20_copy
        ''');
        await txn.execute('''
          INSERT INTO workshop_inspection_items(
            id, inspectionId, category, sectionTitle, title, responseType,
            responseValue, status, mandatory, repairRequired, notes, photoCount,
            displayOrder
          )
          SELECT
            id, inspectionId, category, sectionTitle, title, responseType,
            responseValue, status, mandatory, repairRequired, notes, photoCount,
            displayOrder
          FROM workshop_inspection_items_v20_copy
        ''');
        await txn.execute('''
          INSERT INTO workshop_inspection_photos(
            id, inspectionId, inspectionItemId, filePath, createdAt
          )
          SELECT id, inspectionId, inspectionItemId, filePath, createdAt
          FROM workshop_inspection_photos_v20_copy
        ''');
        await txn.execute('''
          INSERT INTO workshop_repair_jobs(
            id, jobNumber, inspectionId, inspectionItemId, vehicleId,
            vehicleRegistration, title, description, priority, status,
            technicianId, technicianName, partsRequired, estimatedHours,
            actualHours, estimatedCost, actualCost, roadworthy, createdAt,
            startedAt, completedAt
          )
          SELECT
            id, jobNumber, inspectionId, inspectionItemId, vehicleId,
            vehicleRegistration, title, description, priority, status,
            technicianIdText, technicianName, partsRequired, estimatedHours,
            actualHours, estimatedCost, actualCost, roadworthy, createdAt,
            startedAt, completedAt
          FROM workshop_repair_jobs_v20_copy
        ''');

        await txn.execute('DROP TABLE workshop_inspection_photos_v20_copy');
        await txn.execute('DROP TABLE workshop_repair_jobs_v20_copy');
        await txn.execute('DROP TABLE workshop_inspection_items_v20_copy');
        await txn.execute('DROP TABLE workshop_inspections_v20_copy');
      });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON');
    }
  }

  Future<void> _createWorkshopInspectionTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE workshop_inspections(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionNumber TEXT NOT NULL,
        vehicleId INTEGER NOT NULL,
        registration TEXT NOT NULL,
        fleetNumber TEXT NOT NULL,
        templateId INTEGER,
        templateName TEXT,
        technicianId TEXT,
        technicianName TEXT NOT NULL,
        driverId INTEGER,
        driverName TEXT,
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
    await db.execute('''
      CREATE TABLE workshop_inspection_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionId INTEGER NOT NULL,
        category TEXT NOT NULL,
        sectionTitle TEXT,
        title TEXT NOT NULL,
        responseType TEXT NOT NULL DEFAULT 'passFailNotApplicable',
        responseValue TEXT,
        status TEXT NOT NULL,
        mandatory INTEGER NOT NULL DEFAULT 1,
        repairRequired INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        photoCount INTEGER NOT NULL DEFAULT 0,
        displayOrder INTEGER NOT NULL,
        FOREIGN KEY(inspectionId) REFERENCES workshop_inspections(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE workshop_inspection_photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionId INTEGER NOT NULL,
        inspectionItemId INTEGER NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(inspectionId) REFERENCES workshop_inspections(id) ON DELETE CASCADE,
        FOREIGN KEY(inspectionItemId) REFERENCES workshop_inspection_items(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE workshop_repair_jobs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jobNumber TEXT NOT NULL,
        inspectionId INTEGER NOT NULL,
        inspectionItemId INTEGER,
        vehicleId INTEGER NOT NULL,
        vehicleRegistration TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        technicianId TEXT,
        technicianName TEXT NOT NULL DEFAULT '',
        partsRequired INTEGER NOT NULL DEFAULT 0,
        estimatedHours REAL NOT NULL DEFAULT 0,
        actualHours REAL NOT NULL DEFAULT 0,
        estimatedCost REAL NOT NULL DEFAULT 0,
        actualCost REAL NOT NULL DEFAULT 0,
        roadworthy INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        FOREIGN KEY(inspectionId) REFERENCES workshop_inspections(id) ON DELETE CASCADE
      )
    ''');
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
        templateId INTEGER,
        templateName TEXT,
        technicianId TEXT,
        technicianName TEXT NOT NULL,
        driverId INTEGER,
        driverName TEXT,
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

    await db.execute('''
      CREATE TABLE workshop_inspection_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionId INTEGER NOT NULL,
        category TEXT NOT NULL,
        sectionTitle TEXT,
        title TEXT NOT NULL,
        responseType TEXT NOT NULL DEFAULT 'passFailNotApplicable',
        responseValue TEXT,
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
      CREATE TABLE workshop_inspection_photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspectionId INTEGER NOT NULL,
        inspectionItemId INTEGER NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(inspectionId)
          REFERENCES workshop_inspections(id)
          ON DELETE CASCADE,
        FOREIGN KEY(inspectionItemId)
          REFERENCES workshop_inspection_items(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE workshop_repair_jobs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jobNumber TEXT NOT NULL,
        inspectionId INTEGER NOT NULL,
        inspectionItemId INTEGER,
        vehicleId INTEGER NOT NULL,
        vehicleRegistration TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        technicianId TEXT,
        technicianName TEXT NOT NULL DEFAULT '',
        partsRequired INTEGER NOT NULL DEFAULT 0,
        estimatedHours REAL NOT NULL DEFAULT 0,
        actualHours REAL NOT NULL DEFAULT 0,
        estimatedCost REAL NOT NULL DEFAULT 0,
        actualCost REAL NOT NULL DEFAULT 0,
        roadworthy INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        FOREIGN KEY(inspectionId)
          REFERENCES workshop_inspections(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inspection_templates(
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
      CREATE TABLE inspection_template_sections(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        templateId INTEGER NOT NULL,
        title TEXT NOT NULL,
        displayOrder INTEGER NOT NULL,
        FOREIGN KEY(templateId)
          REFERENCES inspection_templates(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inspection_template_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        templateId INTEGER NOT NULL,
        sectionId INTEGER,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        responseType TEXT NOT NULL DEFAULT 'passFailNotApplicable',
        description TEXT,
        displayOrder INTEGER NOT NULL,
        mandatory INTEGER NOT NULL DEFAULT 1,
        criticalSafetyItem INTEGER NOT NULL DEFAULT 0,
        autoCreateRepair INTEGER NOT NULL DEFAULT 1,
        repairPriority TEXT NOT NULL DEFAULT 'medium',
        roadworthyImpact TEXT NOT NULL DEFAULT 'none',
        photoRequiredOnFail INTEGER NOT NULL DEFAULT 0,
        allowNotes INTEGER NOT NULL DEFAULT 1,
        defaultStatus TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(templateId)
          REFERENCES inspection_templates(id)
          ON DELETE CASCADE,
        FOREIGN KEY(sectionId)
          REFERENCES inspection_template_sections(id)
          ON DELETE SET NULL
      )
    ''');
  }
}
