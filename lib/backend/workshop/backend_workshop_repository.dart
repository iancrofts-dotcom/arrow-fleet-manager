import 'dart:typed_data';

import '../documents/backend_fleet_document.dart';
import 'backend_workshop_evidence.dart';
import 'backend_workshop_gateway.dart';
import 'backend_workshop_inspection.dart';
import 'backend_workshop_inspection_item.dart';
import 'backend_workshop_repair_job.dart';
import 'backend_workshop_template.dart';
import 'backend_workshop_writes.dart';

class BackendWorkshopRepository {
  const BackendWorkshopRepository(this._gateway);

  final BackendWorkshopGateway _gateway;

  Future<List<BackendWorkshopInspection>> listInspections() async =>
      (await _gateway.listInspections())
          .map(BackendWorkshopInspection.fromJson)
          .toList(growable: false);

  Future<BackendWorkshopInspection?> getInspection(String id) async {
    final row = await _gateway.getInspection(id);
    return row == null ? null : BackendWorkshopInspection.fromJson(row);
  }

  Future<List<BackendWorkshopInspectionItem>> listInspectionItems(
    String inspectionId,
  ) async => (await _gateway.listInspectionItems(
    inspectionId,
  )).map(BackendWorkshopInspectionItem.fromJson).toList(growable: false);

  Future<List<BackendWorkshopRepairJob>> listRepairJobs({
    String? inspectionId,
  }) async => (await _gateway.listRepairJobs(
    inspectionId: inspectionId,
  )).map(BackendWorkshopRepairJob.fromJson).toList(growable: false);

  Future<List<BackendWorkshopTechnician>> listTechnicians() async =>
      (await _gateway.listTechnicians())
          .map(BackendWorkshopTechnician.fromJson)
          .toList(growable: false);

  Future<List<BackendWorkshopTemplate>> listTemplates() async =>
      (await _gateway.listTemplates())
          .map(BackendWorkshopTemplate.fromJson)
          .toList(growable: false);

  Future<List<BackendWorkshopTemplateItem>> listTemplateItems(
    String templateId,
  ) async => (await _gateway.listTemplateItems(
    templateId,
  )).map(BackendWorkshopTemplateItem.fromJson).toList(growable: false);

  Future<List<BackendWorkshopEvidence>> listEvidence(
    String inspectionItemId,
  ) async => (await _gateway.listEvidence(
    inspectionItemId,
  )).map(BackendWorkshopEvidence.fromJson).toList(growable: false);

  Future<List<BackendFleetDocument>> listDocuments() async =>
      (await _gateway.listDocuments())
          .map(BackendFleetDocument.fromJson)
          .toList(growable: false);

  Future<BackendWorkshopInspection> createInspection(
    BackendWorkshopInspectionCreate value,
  ) async {
    final id = await _gateway.createInspection({
      'vehicle_id': value.vehicleId,
      'inspection_type': value.inspectionType,
      'mileage': value.mileage,
      'notes': value.notes,
      'technician_profile_id': value.technicianProfileId,
    });
    return _reloadCreatedInspection(id);
  }

  Future<BackendWorkshopInspection> createInspectionFromTemplate(
    BackendWorkshopTemplateInspectionCreate value,
  ) async {
    final id = await _gateway.createInspectionFromTemplate({
      'vehicle_id': value.vehicleId,
      'template_id': value.templateId,
      'inspection_type': value.inspectionType,
      'mileage': value.mileage,
      'notes': value.notes,
      'technician_profile_id': value.technicianProfileId,
    });
    return _reloadCreatedInspection(id);
  }

  Future<BackendWorkshopInspection> _reloadCreatedInspection(String id) async {
    final created = await getInspection(id);
    if (created == null) {
      throw StateError('Created inspection could not be reloaded.');
    }
    return created;
  }

  Future<String> saveInspectionItem(BackendWorkshopInspectionItemWrite value) =>
      _gateway.saveInspectionItem({
        'id': value.id,
        'inspection_id': value.inspectionId,
        'category': value.category,
        'section_title': value.sectionTitle,
        'title': value.title,
        'response_type': value.responseType,
        'response_value': value.responseValue,
        'status': value.status,
        'mandatory': value.mandatory,
        'repair_required': value.repairRequired,
        'notes': value.notes,
        'display_order': value.displayOrder,
      });

  Future<String> createRepairJob(BackendWorkshopRepairJobCreate value) =>
      _gateway.createRepairJob({
        'inspection_id': value.inspectionId,
        'inspection_item_id': value.inspectionItemId,
        'title': value.title,
        'description': value.description,
        'priority': value.priority,
        'technician_profile_id': value.technicianProfileId,
        'parts_required': value.partsRequired,
        'estimated_hours': value.estimatedHours,
        'estimated_cost': value.estimatedCost,
      });

  Future<void> updateRepairJob(
    String id,
    BackendWorkshopRepairJobUpdate value,
  ) => _gateway.updateRepairJob(id, {
    'status': value.status,
    'parts_required': value.partsRequired,
    'actual_hours': value.actualHours,
    'actual_cost': value.actualCost,
    'roadworthy': value.roadworthy,
    'work_notes': value.workNotes,
    'parts_notes': value.partsNotes,
    'technician_mileage': value.technicianMileage,
  });

  Future<void> signOffRepairJob(
    String id,
    BackendWorkshopRepairJobUpdate value,
  ) {
    final gateway = _gateway;
    if (gateway is! BackendWorkshopRepairSignOffGateway) {
      throw UnsupportedError(
        'Workshop repair sign-off is not supported by this backend.',
      );
    }
    return (gateway as BackendWorkshopRepairSignOffGateway)
        .signOffRepairJob(id, {
          'roadworthy': value.roadworthy,
          'actual_hours': value.actualHours,
          'actual_cost': value.actualCost,
          'work_notes': value.workNotes,
          'parts_notes': value.partsNotes,
        });
  }

  Future<String> saveTemplate(BackendWorkshopTemplateWrite value) {
    final gateway = _gateway;
    if (gateway is! BackendWorkshopTemplateWriteGateway) {
      throw UnsupportedError(
        'Workshop template writes are not supported by this backend.',
      );
    }
    return (gateway as BackendWorkshopTemplateWriteGateway).saveTemplate({
      'id': value.id,
      'name': value.name,
      'description': value.description,
      'inspection_type': value.inspectionType,
      'is_active': value.isActive,
      'items': [
        for (final item in value.items)
          {
            'section_title': item.sectionTitle,
            'category': item.category,
            'title': item.title,
            'description': item.description,
            'response_type': item.responseType,
            'mandatory': item.mandatory,
            'critical_safety_item': item.criticalSafetyItem,
            'auto_create_repair': item.autoCreateRepair,
            'repair_priority': item.repairPriority,
            'roadworthy_impact': item.roadworthyImpact,
            'photo_required_on_fail': item.photoRequiredOnFail,
            'allow_notes': item.allowNotes,
            'default_status': item.defaultStatus,
            'display_order': item.displayOrder,
          },
      ],
    });
  }

  Future<void> assignInspectionTechnician(
    String inspectionId,
    String? technicianProfileId,
  ) => _gateway.assignInspectionTechnician(inspectionId, technicianProfileId);

  Future<void> assignRepairTechnician(
    String repairJobId,
    String? technicianProfileId,
  ) => _gateway.assignRepairTechnician(repairJobId, technicianProfileId);

  Future<void> completeInspection(String inspectionId) =>
      _gateway.completeInspection(inspectionId);

  Future<void> signOffInspection(String inspectionId) =>
      _gateway.signOffInspection(inspectionId);

  Future<void> uploadInspectionEvidence({
    required String inspectionId,
    required String inspectionItemId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    String caption = '',
  }) => _gateway.uploadInspectionEvidence(
    inspectionId: inspectionId,
    inspectionItemId: inspectionItemId,
    fileName: fileName,
    bytes: bytes,
    contentType: contentType,
    caption: caption,
  );

  Future<String> createEvidenceSignedUrl(String storagePath) =>
      _gateway.createEvidenceSignedUrl(storagePath);

  Future<Uint8List> downloadEvidence(String storagePath) {
    final gateway = _gateway;
    if (gateway is! BackendWorkshopEvidenceDownloadGateway) {
      throw UnsupportedError(
        'Workshop evidence download is not supported by this backend.',
      );
    }
    return (gateway as BackendWorkshopEvidenceDownloadGateway).downloadEvidence(
      storagePath,
    );
  }
}
