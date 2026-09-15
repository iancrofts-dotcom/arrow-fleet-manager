import 'dart:io';

import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/backend_workshop_writes.dart';
import '../models/inspection_checklist_item.dart';
import '../models/inspection_wizard_data.dart';

/// Persists the original in-memory FleetIQ inspection wizard to Supabase only
/// when the operator finishes the walkthrough.
class CentralInspectionWizardSaveService {
  const CentralInspectionWizardSaveService(this._repository);

  final BackendWorkshopRepository _repository;

  Future<BackendWorkshopInspection> saveInspection(
    InspectionWizardData data,
  ) async {
    final vehicleId = data.centralVehicleId;
    final templateId = data.centralTemplateId;
    final inspectionType = data.inspectionType;
    final mileage = data.mileage;
    if (vehicleId == null ||
        templateId == null ||
        inspectionType == null ||
        mileage == null) {
      throw StateError('The central inspection setup is incomplete.');
    }

    final created = await _repository.createInspectionFromTemplate(
      BackendWorkshopTemplateInspectionCreate(
        vehicleId: vehicleId,
        templateId: templateId,
        inspectionType: inspectionType.name,
        mileage: mileage,
        notes: data.finalNotes ?? data.notes,
        technicianProfileId: data.technicianId,
      ),
    );

    final persistedItems = await _repository.listInspectionItems(created.id);
    if (persistedItems.length != data.checklistItems.length) {
      throw StateError(
        'Central checklist does not match the completed wizard.',
      );
    }

    final byTemplateItem = {
      for (final item in persistedItems)
        if (item.templateItemId != null) item.templateItemId!: item,
    };
    final savedIds = <int, String>{};

    for (var index = 0; index < data.checklistItems.length; index++) {
      final wizardItem = data.checklistItems[index];
      final persisted = byTemplateItem[wizardItem.id] ?? persistedItems[index];
      final savedId = await _repository.saveInspectionItem(
        BackendWorkshopInspectionItemWrite(
          id: persisted.id,
          inspectionId: created.id,
          category: persisted.category,
          sectionTitle: persisted.sectionTitle,
          title: persisted.title,
          responseType: persisted.responseType,
          responseValue: wizardItem.responseValue.trim().isEmpty
              ? null
              : wizardItem.responseValue.trim(),
          status: _status(wizardItem.status),
          mandatory: wizardItem.mandatory,
          repairRequired: wizardItem.repairRequired,
          notes: wizardItem.notes,
          displayOrder: persisted.displayOrder,
        ),
      );
      savedIds[index] = savedId;

      for (final path in wizardItem.photos) {
        await _uploadPhoto(
          inspectionId: created.id,
          inspectionItemId: savedId,
          path: path,
          caption: wizardItem.title,
        );
      }
    }

    final automaticallyCreated = await _repository.listRepairJobs(
      inspectionId: created.id,
    );
    final existingItemIds = automaticallyCreated
        .map((job) => job.inspectionItemId)
        .whereType<String>()
        .toSet();

    for (final repair in data.repairJobs) {
      final sourceIndex = repair.inspectionItemId - 1;
      final itemId = savedIds[sourceIndex];
      if (itemId == null) {
        throw StateError('Repair job source item could not be resolved.');
      }
      if (existingItemIds.contains(itemId)) {
        continue;
      }
      await _repository.createRepairJob(
        BackendWorkshopRepairJobCreate(
          inspectionId: created.id,
          inspectionItemId: itemId,
          title: repair.title,
          description: repair.description,
          priority: repair.priority.name,
          technicianProfileId: repair.technicianId,
          partsRequired: repair.partsRequired,
          estimatedHours: repair.estimatedHours,
          estimatedCost: repair.estimatedCost,
        ),
      );
      existingItemIds.add(itemId);
    }

    await _repository.completeInspection(created.id);

    // A clean inspection can move straight through management sign-off.
    // Inspections with repair work deliberately remain awaitingRepair until
    // those jobs are resolved, matching the central Workshop safety boundary.
    if (data.repairJobs.isEmpty) {
      await _repository.signOffInspection(created.id);
    }

    final reloaded = await _repository.getInspection(created.id);
    if (reloaded == null) {
      throw StateError('Saved central inspection could not be reloaded.');
    }
    return reloaded;
  }

  Future<void> _uploadPhoto({
    required String inspectionId,
    required String inspectionItemId,
    required String path,
    required String caption,
  }) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    await _repository.uploadInspectionEvidence(
      inspectionId: inspectionId,
      inspectionItemId: inspectionItemId,
      fileName: file.uri.pathSegments.isEmpty
          ? 'inspection-photo.jpg'
          : file.uri.pathSegments.last,
      bytes: bytes,
      contentType: _contentType(path),
      caption: caption,
    );
  }

  String _status(ChecklistStatus status) => switch (status) {
    ChecklistStatus.pass => 'pass',
    ChecklistStatus.advisory => 'advisory',
    ChecklistStatus.fail => 'fail',
    ChecklistStatus.notApplicable => 'notApplicable',
    ChecklistStatus.pending => 'notApplicable',
  };

  String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
