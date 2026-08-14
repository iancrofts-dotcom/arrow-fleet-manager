import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../models/inspection_photo.dart';

/// Handles persistence of photographs attached to workshop inspections.
class InspectionPhotoRepository {
  InspectionPhotoRepository({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  static const String _table =
      'workshop_inspection_photos';

  Future<Database> get _db async =>
      await _database.database();

  Future<int> createPhoto(
    InspectionPhoto photo,
  ) async {
    final db = await _db;

    return db.insert(
      _table,
      photo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> createPhotos(
    List<InspectionPhoto> photos, {
    DatabaseExecutor? executor,
  }) async {
    if (photos.isEmpty) return;

    final db = executor ?? await _db;
    final batch = db.batch();

    for (final photo in photos) {
      batch.insert(
        _table,
        photo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<InspectionPhoto>> getForInspection(
    int inspectionId,
  ) async {
    final db = await _db;

    final result = await db.query(
      _table,
      where: 'inspectionId = ?',
      whereArgs: [inspectionId],
      orderBy: 'createdAt ASC',
    );

    return result
        .map(InspectionPhoto.fromMap)
        .toList();
  }

  Future<List<InspectionPhoto>> getForInspectionItem(
    int inspectionItemId,
  ) async {
    final db = await _db;

    final result = await db.query(
      _table,
      where: 'inspectionItemId = ?',
      whereArgs: [inspectionItemId],
      orderBy: 'createdAt ASC',
    );

    return result
        .map(InspectionPhoto.fromMap)
        .toList();
  }

  Future<int> deletePhoto(int id) async {
    final db = await _db;

    return db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteForInspection(
    int inspectionId,
  ) async {
    final db = await _db;

    return db.delete(
      _table,
      where: 'inspectionId = ?',
      whereArgs: [inspectionId],
    );
  }

  Future<int> deleteForInspectionItem(
    int inspectionItemId,
  ) async {
    final db = await _db;

    return db.delete(
      _table,
      where: 'inspectionItemId = ?',
      whereArgs: [inspectionItemId],
    );
  }
}
