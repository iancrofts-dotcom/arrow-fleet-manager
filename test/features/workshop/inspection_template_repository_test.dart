import 'dart:io';

import 'package:arrow_fleet_manager/database/app_database.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_template.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_template_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_template_section.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:arrow_fleet_manager/features/workshop/repositories/inspection_template_repository.dart';
import 'package:arrow_fleet_manager/features/workshop/repositories/workshop_repository.dart';
import 'package:arrow_fleet_manager/features/workshop/services/inspection_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test(
    'migrates v24 templates to v25 without losing template content',
    () async {
      final directory = await Directory.systemTemp.createTemp('arrow_v24_');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/workshop.db';
      final v24 = await openDatabase(
        path,
        version: 24,
        onCreate: (db, _) => _createV24TemplateSchema(db),
      );
      await _seedV24TemplateData(v24);
      await v24.close();

      final database = AppDatabase(databasePath: path);
      addTearDown(database.close);
      final repository = InspectionTemplateRepository(database: database);
      final migrated = await database.database();

      expect(await migrated.getVersion(), 25);
      final template = await repository.getTemplate(1);
      expect(template, isNotNull);
      expect(template!.name, 'Legacy safety check');
      expect(template.inspectionType, isNull);
      expect(template.version, 1);
      expect(template.sourceReference, isNull);

      final sections = await repository.getTemplateSections(1);
      expect(sections.map((section) => section.title), ['Brakes']);
      final items = await repository.getTemplateItems(1);
      expect(items.map((item) => item.title), [
        'Brake fluid level',
        'Brake pedal travel',
      ]);
      expect(items.map((item) => item.displayOrder), [0, 1]);
      expect(
        Sqflite.firstIntValue(
          await migrated.rawQuery('SELECT COUNT(*) FROM workshop_inspections'),
        ),
        1,
      );
    },
  );

  test('round-trips template type, version and source reference', () async {
    final harness = await _TemplateHarness.create();
    addTearDown(harness.dispose);
    final template = _template(
      inspectionType: WorkshopInspectionType.annualInspection,
      version: 3,
      sourceReference: 'HGV-2026-ANNUAL',
    );

    final id = await harness.templates.createTemplate(template);
    final reloaded = await harness.templates.getTemplate(id);

    expect(reloaded!.inspectionType, WorkshopInspectionType.annualInspection);
    expect(reloaded.version, 3);
    expect(reloaded.sourceReference, 'HGV-2026-ANNUAL');

    final legacyId = await harness.templates.createTemplate(
      _template(name: 'Legacy template'),
    );
    final legacy = await harness.templates.getTemplate(legacyId);
    expect(legacy!.inspectionType, isNull);
    expect(legacy.version, 1);
    expect(legacy.sourceReference, isNull);
  });

  test(
    'persists the intended create, edit and duplicate version semantics',
    () async {
      final harness = await _TemplateHarness.create();
      addTearDown(harness.dispose);
      final createdId = await harness.templates.createTemplate(
        _template(name: 'Original'),
      );
      final created = (await harness.templates.getTemplate(createdId))!;
      expect(created.version, 1);

      await harness.templates.replaceTemplateContent(
        templateId: createdId,
        sections: [_section(createdId, 'Original section')],
        sectionItems: [
          [_item(createdId, title: 'Original item', displayOrder: 0)],
        ],
      );

      final edited = created.copyWith(
        name: 'Original updated',
        version: created.version + 1,
        updatedAt: DateTime(2026, 9, 5, 10),
      );
      await harness.templates.updateTemplate(edited);
      expect((await harness.templates.getTemplate(createdId))!.version, 2);

      final duplicateId = await harness.templates.createTemplate(
        _template(
          name: 'Original copy',
          inspectionType: created.inspectionType,
          version: 1,
        ),
      );
      await harness.templates.replaceTemplateContent(
        templateId: duplicateId,
        sections: [_section(createdId, 'Original section')],
        sectionItems: [
          [_item(createdId, title: 'Original item', displayOrder: 0)],
        ],
      );

      final duplicate = (await harness.templates.getTemplate(duplicateId))!;
      expect(duplicateId, isNot(createdId));
      expect(duplicate.version, 1);
      final originalItems = await harness.templates.getTemplateItems(createdId);
      final duplicateItems = await harness.templates.getTemplateItems(
        duplicateId,
      );
      expect(duplicateItems.single.id, isNot(originalItems.single.id));
      expect(duplicateItems.single.templateId, duplicateId);

      await harness.templates.replaceTemplateContent(
        templateId: duplicateId,
        sections: [_section(duplicateId, 'Copy section')],
        sectionItems: [
          [_item(duplicateId, title: 'Changed copy item', displayOrder: 0)],
        ],
      );
      expect(
        (await harness.templates.getTemplateItems(createdId)).single.title,
        'Original item',
      );
      expect(
        (await harness.templates.getTemplateItems(duplicateId)).single.title,
        'Changed copy item',
      );
    },
  );

  test(
    'filters active templates by inspection type while retaining legacy templates',
    () async {
      final harness = await _TemplateHarness.create();
      addTearDown(harness.dispose);
      await harness.templates.createTemplate(
        _template(
          name: 'Scheduled service',
          inspectionType: WorkshopInspectionType.scheduledService,
        ),
      );
      await harness.templates.createTemplate(
        _template(
          name: 'Annual only',
          inspectionType: WorkshopInspectionType.annualInspection,
        ),
      );
      await harness.templates.createTemplate(
        _template(name: 'Legacy template'),
      );
      await harness.templates.createTemplate(
        _template(
          name: 'Inactive scheduled service',
          inspectionType: WorkshopInspectionType.scheduledService,
          isActive: false,
        ),
      );

      final templates = await harness.templates
          .getActiveTemplatesForInspectionType(
            WorkshopInspectionType.scheduledService,
          );

      expect(templates.map((template) => template.name), [
        'Legacy template',
        'Scheduled service',
      ]);
    },
  );

  test(
    'completed inspection items retain template wording and order after edits',
    () async {
      final harness = await _TemplateHarness.create();
      addTearDown(harness.dispose);
      final templateId = await harness.templates.createTemplate(
        _template(name: 'Snapshot template'),
      );
      await harness.templates.replaceTemplateContent(
        templateId: templateId,
        sections: [_section(templateId, 'Safety')],
        sectionItems: [
          [
            _item(templateId, title: 'Original first', displayOrder: 0),
            _item(templateId, title: 'Original second', displayOrder: 1),
          ],
        ],
      );

      final inspectionId =
          await InspectionGenerator(
            WorkshopRepository(database: harness.database),
            harness.templates,
          ).generateInspection(
            inspection: _inspection(templateId),
            templateId: templateId,
          );

      final original = (await harness.templates.getTemplate(templateId))!;
      await harness.templates.updateTemplate(original.copyWith(version: 2));
      await harness.templates.replaceTemplateContent(
        templateId: templateId,
        sections: [_section(templateId, 'Reordered safety')],
        sectionItems: [
          [
            _item(templateId, title: 'Edited second', displayOrder: 0),
            _item(templateId, title: 'Edited first', displayOrder: 1),
          ],
        ],
      );

      final historical = await WorkshopRepository(
        database: harness.database,
      ).getInspectionItems(inspectionId);
      expect(historical.map((item) => item.title), [
        'Original first',
        'Original second',
      ]);
      expect(historical.map((item) => item.displayOrder), [0, 1]);
    },
  );
}

InspectionTemplate _template({
  String name = 'Template',
  WorkshopInspectionType? inspectionType,
  int version = 1,
  String? sourceReference,
  bool isActive = true,
}) {
  final now = DateTime(2026, 9, 5, 9);
  return InspectionTemplate(
    name: name,
    description: 'Workshop template',
    vehicleType: WorkshopVehicleType.van,
    inspectionType: inspectionType,
    version: version,
    sourceReference: sourceReference,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

InspectionTemplateSection _section(int templateId, String title) =>
    InspectionTemplateSection(
      templateId: templateId,
      title: title,
      displayOrder: 0,
    );

InspectionTemplateItem _item(
  int templateId, {
  required String title,
  required int displayOrder,
}) => InspectionTemplateItem(
  templateId: templateId,
  category: InspectionCategory.brakes,
  title: title,
  displayOrder: displayOrder,
);

WorkshopInspection _inspection(int templateId) {
  final now = DateTime(2026, 9, 5, 9);
  return WorkshopInspection(
    inspectionNumber: 'SNAPSHOT-1',
    vehicleId: 1,
    registration: 'AB12 CDE',
    fleetNumber: 'F-1',
    templateId: templateId,
    templateName: 'Snapshot template',
    technicianName: 'Workshop One',
    inspectionType: WorkshopInspectionType.scheduledService,
    status: WorkshopInspectionStatus.completed,
    vehicleStatus: VehicleWorkshopStatus.roadworthy,
    dateStarted: now,
    dateCompleted: now,
    mileage: 1000,
    overallResult: InspectionResult.pass,
    inspectionScore: 100,
    criticalFailures: 0,
    advisories: 0,
    repairsRequired: 0,
    labourHours: 0,
    totalCost: 0,
    notes: '',
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _createV24TemplateSchema(Database db) async {
  await db.execute('''
    CREATE TABLE workshop_inspections(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      inspectionNumber TEXT NOT NULL
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
      displayOrder INTEGER NOT NULL
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
      isActive INTEGER NOT NULL DEFAULT 1
    )
  ''');
}

Future<void> _seedV24TemplateData(Database db) async {
  await db.insert('workshop_inspections', {'inspectionNumber': 'WI-24-1'});
  await db.insert('inspection_templates', {
    'id': 1,
    'name': 'Legacy safety check',
    'description': 'Existing template',
    'vehicleType': 'van',
    'isDefault': 0,
    'isActive': 1,
    'createdAt': '2026-09-01T09:00:00.000',
    'updatedAt': '2026-09-01T09:00:00.000',
  });
  await db.insert('inspection_template_sections', {
    'id': 1,
    'templateId': 1,
    'title': 'Brakes',
    'displayOrder': 0,
  });
  for (var index = 0; index < 2; index++) {
    await db.insert('inspection_template_items', {
      'templateId': 1,
      'sectionId': 1,
      'category': 'brakes',
      'title': index == 0 ? 'Brake fluid level' : 'Brake pedal travel',
      'responseType': 'passFailNotApplicable',
      'description': '',
      'displayOrder': index,
      'mandatory': 1,
      'criticalSafetyItem': 0,
      'autoCreateRepair': 1,
      'repairPriority': 'medium',
      'roadworthyImpact': 'none',
      'photoRequiredOnFail': 0,
      'allowNotes': 1,
      'defaultStatus': 'notApplicable',
      'isActive': 1,
    });
  }
}

class _TemplateHarness {
  _TemplateHarness._(this.directory, this.database, this.templates);

  final Directory directory;
  final AppDatabase database;
  final InspectionTemplateRepository templates;

  static Future<_TemplateHarness> create() async {
    final directory = await Directory.systemTemp.createTemp('arrow_template_');
    final database = AppDatabase(databasePath: '${directory.path}/workshop.db');
    return _TemplateHarness._(
      directory,
      database,
      InspectionTemplateRepository(database: database),
    );
  }

  Future<void> dispose() async {
    await database.close();
    await directory.delete(recursive: true);
  }
}
