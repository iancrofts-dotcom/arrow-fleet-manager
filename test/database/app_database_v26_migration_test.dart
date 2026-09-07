import 'dart:io';

import 'package:arrow_fleet_manager/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('migrates v25 records to v26 with nullable taxi fields', () async {
    final directory = await Directory.systemTemp.createTemp('arrow_v25_');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/fleet.db';
    final v25 = await openDatabase(
      path,
      version: 25,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE vehicles (
            id INTEGER PRIMARY KEY, registration TEXT NOT NULL,
            fleetNumber TEXT NOT NULL, make TEXT, model TEXT, year INTEGER,
            vin TEXT, motExpiry TEXT, serviceDue TEXT, active INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE drivers (
            id INTEGER PRIMARY KEY, firstName TEXT NOT NULL,
            lastName TEXT NOT NULL, licenceNumber TEXT NOT NULL,
            licenceExpiry TEXT, isActive INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE driver_compliance (
            driverId INTEGER PRIMARY KEY, licenceExpiry TEXT NOT NULL,
            cpcExpiry TEXT NOT NULL, medicalExpiry TEXT NOT NULL,
            dbsExpiry TEXT, lastUpdated TEXT NOT NULL
          )
        ''');
      },
    );
    await v25.insert('vehicles', {
      'id': 1,
      'registration': 'AB12 CDE',
      'fleetNumber': 'F-1',
      'make': 'Arrow',
      'model': 'Van',
      'year': 2025,
      'vin': 'VIN-1',
      'motExpiry': '2027-01-01',
      'serviceDue': '2026-10-01',
      'active': 1,
    });
    await v25.insert('drivers', {
      'id': 1,
      'firstName': 'Pat',
      'lastName': 'Driver',
      'licenceNumber': 'D-1',
      'licenceExpiry': '2027-01-01',
      'isActive': 1,
    });
    await v25.insert('driver_compliance', {
      'driverId': 1,
      'licenceExpiry': '2027-01-01',
      'cpcExpiry': '2027-01-01',
      'medicalExpiry': '2027-01-01',
      'lastUpdated': '2026-01-01',
    });
    await v25.close();

    final appDatabase = AppDatabase(databasePath: path);
    addTearDown(appDatabase.close);
    final migrated = await appDatabase.database();

    expect(await migrated.getVersion(), 26);
    expect(
      (await migrated.query('vehicles')).single['registration'],
      'AB12 CDE',
    );
    expect((await migrated.query('drivers')).single['firstName'], 'Pat');
    expect((await migrated.query('driver_compliance')).single['driverId'], 1);
    expect(
      (await migrated.rawQuery(
        'PRAGMA table_info(driver_compliance)',
      )).map((row) => row['name']),
      contains('taxiLicenceExpiry'),
    );
    expect(
      (await migrated.rawQuery(
        'PRAGMA table_info(vehicles)',
      )).map((row) => row['name']),
      containsAll([
        'taxiPlateNumber',
        'taxiLicensingAuthority',
        'taxiPlateIssueDate',
        'taxiPlateExpiry',
      ]),
    );
    expect(
      (await migrated.query('vehicles')).single['taxiPlateExpiry'],
      isNull,
    );
    expect(
      (await migrated.query('driver_compliance')).single['taxiLicenceExpiry'],
      isNull,
    );
  });
}
