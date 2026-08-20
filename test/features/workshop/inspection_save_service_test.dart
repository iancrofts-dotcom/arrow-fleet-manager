import 'package:arrow_fleet_manager/features/workshop/models/inspection_checklist_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_photo.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_wizard_data.dart';
import 'package:arrow_fleet_manager/features/workshop/models/repair_job.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:arrow_fleet_manager/features/workshop/repositories/inspection_photo_repository.dart';
import 'package:arrow_fleet_manager/features/workshop/repositories/workshop_repository.dart';
import 'package:arrow_fleet_manager/features/workshop/services/inspection_save_service.dart';
import 'package:arrow_fleet_manager/features/workshop/services/repair_job_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test(
    'assigns persisted inspection and repair identities after insert',
    () async {
      final store = _WorkshopStore();
      final service = _service(store);

      final firstId = await service.saveInspection(_data(repairs: 2));
      final secondId = await service.saveInspection(_data(repairs: 1));

      expect(firstId, 1);
      expect(secondId, 2);
      expect(store.inspections[firstId]!.inspectionNumber, 'WI-2026-000001');
      expect(store.inspections[secondId]!.inspectionNumber, 'WI-2026-000002');
      expect(
        store.inspections.values.map((item) => item.inspectionNumber).toSet(),
        hasLength(2),
      );

      final firstJobs = store.jobs
          .where((job) => job.inspectionId == firstId)
          .toList();
      final secondJobs = store.jobs
          .where((job) => job.inspectionId == secondId)
          .toList();
      expect(firstJobs.map((job) => job.jobNumber), [
        'RJ-2026-1-001',
        'RJ-2026-1-002',
      ]);
      expect(secondJobs.single.jobNumber, 'RJ-2026-2-001');
      expect(firstJobs.every((job) => job.inspectionItemId > 0), isTrue);
    },
  );

  test(
    'rolls back a failed save and retry persists one complete inspection',
    () async {
      final store = _WorkshopStore()..failRepairInsert = true;
      final service = _service(store);
      final data = _data(repairs: 1, includePhoto: true);

      await expectLater(service.saveInspection(data), throwsStateError);
      expect(store.inspections, isEmpty);
      expect(store.items, isEmpty);
      expect(store.photos, isEmpty);
      expect(store.jobs, isEmpty);

      store.failRepairInsert = false;
      final inspectionId = await service.saveInspection(data);

      expect(inspectionId, 1);
      expect(store.inspections, hasLength(1));
      expect(store.items, hasLength(2));
      expect(store.photos, hasLength(1));
      expect(store.jobs, hasLength(1));
      expect(store.jobs.single.jobNumber, 'RJ-2026-1-001');
    },
  );
}

InspectionSaveService _service(_WorkshopStore store) => InspectionSaveService(
  repository: _FakeWorkshopRepository(store),
  photoRepository: _FakePhotoRepository(store),
);

InspectionWizardData _data({required int repairs, bool includePhoto = false}) {
  final data = InspectionWizardData()
    ..vehicleId = 7
    ..registration = 'AB12 CDE'
    ..fleetNumber = 'F-7'
    ..mileage = 1200
    ..technicianId = 'tech-1'
    ..technicianName = 'Technician One'
    ..inspectionType = WorkshopInspectionType.defectInspection
    ..dateStarted = DateTime(2026, 8, 20)
    ..createdAt = DateTime(2026, 8, 20)
    ..updatedAt = DateTime(2026, 8, 20)
    ..overallResult = InspectionResult.fail
    ..vehicleStatus = VehicleWorkshopStatus.awaitingRepair;
  data.checklistItems = List.generate(2, (index) {
    final requiresRepair = index < repairs;
    return InspectionChecklistItem(
      id: 'item-$index',
      category: 'Brakes',
      title: 'Checklist item $index',
      status: requiresRepair ? ChecklistStatus.fail : ChecklistStatus.pass,
      repairRequired: requiresRepair,
      photos: includePhoto && index == 0 ? ['evidence.jpg'] : [],
    );
  });
  data.repairsRequired = repairs;
  data.repairJobs = RepairJobGenerator().generate(
    inspectionId: 0,
    vehicleId: data.vehicleId!,
    vehicleRegistration: data.registration!,
    items: data.checklistItems,
    technicianId: data.technicianId,
    technicianName: data.technicianName!,
    generateJobNumbers: false,
  );
  return data;
}

class _WorkshopStore {
  var _nextInspectionId = 1;
  var _nextItemId = 1;
  var _nextJobId = 1;
  bool failRepairInsert = false;
  final inspections = <int, WorkshopInspection>{};
  final items = <int, InspectionItem>{};
  final photos = <InspectionPhoto>[];
  final jobs = <RepairJob>[];

  _WorkshopStoreSnapshot snapshot() => _WorkshopStoreSnapshot(
    nextInspectionId: _nextInspectionId,
    nextItemId: _nextItemId,
    nextJobId: _nextJobId,
    inspections: Map.of(inspections),
    items: Map.of(items),
    photos: List.of(photos),
    jobs: List.of(jobs),
  );

  void restore(_WorkshopStoreSnapshot snapshot) {
    _nextInspectionId = snapshot.nextInspectionId;
    _nextItemId = snapshot.nextItemId;
    _nextJobId = snapshot.nextJobId;
    inspections
      ..clear()
      ..addAll(snapshot.inspections);
    items
      ..clear()
      ..addAll(snapshot.items);
    photos
      ..clear()
      ..addAll(snapshot.photos);
    jobs
      ..clear()
      ..addAll(snapshot.jobs);
  }
}

class _WorkshopStoreSnapshot {
  const _WorkshopStoreSnapshot({
    required this.nextInspectionId,
    required this.nextItemId,
    required this.nextJobId,
    required this.inspections,
    required this.items,
    required this.photos,
    required this.jobs,
  });

  final int nextInspectionId;
  final int nextItemId;
  final int nextJobId;
  final Map<int, WorkshopInspection> inspections;
  final Map<int, InspectionItem> items;
  final List<InspectionPhoto> photos;
  final List<RepairJob> jobs;
}

class _FakeWorkshopRepository extends WorkshopRepository {
  _FakeWorkshopRepository(this.store);

  final _WorkshopStore store;

  @override
  Future<T> transaction<T>(
    Future<T> Function(DatabaseExecutor executor) action,
  ) async {
    final snapshot = store.snapshot();
    try {
      return await action(_NoopDatabaseExecutor());
    } catch (_) {
      store.restore(snapshot);
      rethrow;
    }
  }

  @override
  Future<int> createInspection(
    WorkshopInspection inspection, {
    DatabaseExecutor? executor,
  }) async {
    final id = store._nextInspectionId++;
    store.inspections[id] = inspection.copyWith(id: id);
    return id;
  }

  @override
  Future<int> updateInspection(
    WorkshopInspection inspection, {
    DatabaseExecutor? executor,
  }) async {
    final id = inspection.id!;
    store.inspections[id] = inspection;
    return 1;
  }

  @override
  Future<void> addInspectionItems(
    List<InspectionItem> items, {
    DatabaseExecutor? executor,
  }) async {
    for (final item in items) {
      final id = store._nextItemId++;
      store.items[id] = item.copyWith(id: id);
    }
  }

  @override
  Future<List<InspectionItem>> getInspectionItems(
    int inspectionId, {
    DatabaseExecutor? executor,
  }) async =>
      store.items.values
          .where((item) => item.inspectionId == inspectionId)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  @override
  Future<int> createRepairJob(
    RepairJob job, {
    DatabaseExecutor? executor,
  }) async {
    if (store.failRepairInsert) {
      throw StateError('Repair insert failed.');
    }
    final id = store._nextJobId++;
    store.jobs.add(job.copyWith(id: id));
    return id;
  }
}

class _FakePhotoRepository extends InspectionPhotoRepository {
  _FakePhotoRepository(this.store);

  final _WorkshopStore store;

  @override
  Future<void> createPhotos(
    List<InspectionPhoto> photos, {
    DatabaseExecutor? executor,
  }) async {
    store.photos.addAll(photos);
  }
}

class _NoopDatabaseExecutor implements DatabaseExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
