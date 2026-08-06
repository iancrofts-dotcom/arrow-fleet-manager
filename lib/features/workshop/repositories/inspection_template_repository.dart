import 'package:sqflite/sqflite.dart';

import '../../../database/app_database.dart';
import '../models/inspection_template.dart';
import '../models/inspection_template_item.dart';

/// ============================================================================
/// INSPECTION TEMPLATE REPOSITORY
/// ============================================================================
///
/// Manages workshop inspection templates and their template items.
/// ============================================================================

class InspectionTemplateRepository {
  InspectionTemplateRepository({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase();

  final AppDatabase _database;

  static const String _templateTable = 'inspection_templates';
  static const String _itemTable = 'inspection_template_items';

  Future<Database> get _db async => await _database.database();

  // ==========================================================================
  // TEMPLATE CRUD
  // ==========================================================================

  Future<int> createTemplate(
    InspectionTemplate template,
  ) async {
    final db = await _db;

    return db.insert(
      _templateTable,
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InspectionTemplate>> getTemplates() async {
    final db = await _db;

    final result = await db.query(
      _templateTable,
      orderBy: 'name ASC',
    );

    return result
        .map((map) => InspectionTemplate.fromMap(map))
        .toList();
  }

  Future<InspectionTemplate?> getTemplate(
    int id,
  ) async {
    final db = await _db;

    final result = await db.query(
      _templateTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return InspectionTemplate.fromMap(result.first);
  }

  Future<int> updateTemplate(
    InspectionTemplate template,
  ) async {
    final db = await _db;

    return db.update(
      _templateTable,
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteTemplate(
    int id,
  ) async {
    final db = await _db;

    return db.delete(
      _templateTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================================================
  // TEMPLATE ITEMS
  // ==========================================================================

  Future<int> addTemplateItem(
    InspectionTemplateItem item,
  ) async {
    final db = await _db;

    return db.insert(
      _itemTable,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addTemplateItems(
    List<InspectionTemplateItem> items,
  ) async {
    final db = await _db;

    final batch = db.batch();

    for (final item in items) {
      batch.insert(
        _itemTable,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(
      noResult: true,
    );
  }

  Future<List<InspectionTemplateItem>> getTemplateItems(
    int templateId,
  ) async {
    final db = await _db;

    final result = await db.query(
      _itemTable,
      where: 'templateId = ?',
      whereArgs: [templateId],
      orderBy: 'displayOrder ASC',
    );

    return result
        .map((map) => InspectionTemplateItem.fromMap(map))
        .toList();
  }

  Future<int> deleteTemplateItems(
    int templateId,
  ) async {
    final db = await _db;

    return db.delete(
      _itemTable,
      where: 'templateId = ?',
      whereArgs: [templateId],
    );
  }

  Future<int> getTemplateCount() async {
    final db = await _db;

    final result = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $_templateTable',
      ),
    );

    return result ?? 0;
  }
}