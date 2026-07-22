import 'package:sqflite/sqflite.dart';

Future<void> migrateToV11(Database db) async {
  await db.execute('''
    ALTER TABLE drivers
    ADD COLUMN username TEXT
  ''');
}