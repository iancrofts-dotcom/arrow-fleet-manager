import 'dart:typed_data';
import 'package:arrow_fleet_manager/backend/workshop/backend_workshop_gateway.dart';
import 'package:arrow_fleet_manager/backend/workshop/backend_workshop_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'central Workshop repository maps inspection, items and repairs',
    () async {
      final repository = BackendWorkshopRepository(_FakeWorkshopGateway());

      final inspections = await repository.listInspections();
      final items = await repository.listInspectionItems('inspection-1');
      final repairs = await repository.listRepairJobs(
        inspectionId: 'inspection-1',
      );

      expect(inspections, hasLength(1));
      expect(inspections.single.id, 'inspection-1');
      expect(inspections.single.registration, 'TEST123');
      expect(inspections.single.isOpen, isTrue);
      expect(items.single.repairRequired, isTrue);
      expect(repairs.single.jobNumber, 'RJ-1');
      expect(repairs.single.isOutstanding, isTrue);
    },
  );
}

class _FakeWorkshopGateway implements BackendWorkshopGateway {
  @override
  Future<Map<String, dynamic>?> getInspection(String id) async =>
      id == 'inspection-1' ? _inspection : null;

  @override
  Future<List<Map<String, dynamic>>> listInspectionItems(
    String inspectionId,
  ) async => inspectionId == 'inspection-1' ? [_item] : [];

  @override
  Future<List<Map<String, dynamic>>> listInspections() async => [_inspection];

  @override
  Future<List<Map<String, dynamic>>> listRepairJobs({
    String? inspectionId,
  }) async =>
      inspectionId == null || inspectionId == 'inspection-1' ? [_repair] : [];

  @override
  Future<List<Map<String, dynamic>>> listTechnicians() async => [];
  @override
  Future<List<Map<String, dynamic>>> listTemplates() async => [];
  @override
  Future<List<Map<String, dynamic>>> listTemplateItems(
    String templateId,
  ) async => [];
  @override
  Future<List<Map<String, dynamic>>> listEvidence(
    String inspectionItemId,
  ) async => [];
  @override
  Future<List<Map<String, dynamic>>> listDocuments() async => [];
  @override
  Future<String> createInspectionFromTemplate(Map<String, dynamic> values) =>
      throw UnimplementedError();
  @override
  Future<void> uploadInspectionEvidence({
    required String inspectionId,
    required String inspectionItemId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    String caption = '',
  }) => throw UnimplementedError();
  @override
  Future<String> createEvidenceSignedUrl(String storagePath) =>
      throw UnimplementedError();
  @override
  Future<String> createInspection(Map<String, dynamic> values) =>
      throw UnimplementedError();
  @override
  Future<String> saveInspectionItem(Map<String, dynamic> values) =>
      throw UnimplementedError();
  @override
  Future<String> createRepairJob(Map<String, dynamic> values) =>
      throw UnimplementedError();
  @override
  Future<void> updateRepairJob(String id, Map<String, dynamic> values) =>
      throw UnimplementedError();
  @override
  Future<void> assignInspectionTechnician(
    String inspectionId,
    String? technicianProfileId,
  ) => throw UnimplementedError();
  @override
  Future<void> assignRepairTechnician(
    String repairJobId,
    String? technicianProfileId,
  ) => throw UnimplementedError();
  @override
  Future<void> completeInspection(String inspectionId) =>
      throw UnimplementedError();
  @override
  Future<void> signOffInspection(String inspectionId) =>
      throw UnimplementedError();
}

final _inspection = <String, dynamic>{
  'id': 'inspection-1',
  'legacy_id': 12,
  'inspection_number': 'WI-2026-000012',
  'vehicle_id': 'vehicle-1',
  'registration': 'TEST123',
  'fleet_number': 'F12',
  'template_name': 'Safety Inspection',
  'technician_profile_id': 'profile-1',
  'technician_name': 'Technician One',
  'driver_id': null,
  'driver_name': null,
  'workshop_manager': 'Manager One',
  'inspection_type': 'annualInspection',
  'status': 'awaitingRepair',
  'vehicle_status': 'awaitingRepair',
  'date_started': '2026-09-09T06:00:00.000Z',
  'date_completed': null,
  'mileage': 45000,
  'overall_result': 'fail',
  'inspection_score': 82,
  'critical_failures': 1,
  'advisories': 2,
  'repairs_required': 1,
  'labour_hours': 0,
  'total_cost': 0,
  'notes': 'Brake defect',
  'created_at': '2026-09-09T06:00:00.000Z',
  'updated_at': '2026-09-09T06:00:00.000Z',
};

final _item = <String, dynamic>{
  'id': 'item-1',
  'legacy_id': 44,
  'inspection_id': 'inspection-1',
  'category': 'brakes',
  'section_title': 'Brakes',
  'title': 'Front brake condition',
  'response_type': 'passFailNotApplicable',
  'response_value': null,
  'status': 'fail',
  'mandatory': true,
  'repair_required': true,
  'notes': 'Pads low',
  'photo_count': 1,
  'display_order': 1,
};

final _repair = <String, dynamic>{
  'id': 'repair-1',
  'legacy_id': 99,
  'job_number': 'RJ-1',
  'inspection_id': 'inspection-1',
  'inspection_item_id': 'item-1',
  'vehicle_id': 'vehicle-1',
  'vehicle_registration': 'TEST123',
  'title': 'Replace front pads',
  'description': 'Replace worn front pads',
  'priority': 'high',
  'status': 'open',
  'technician_profile_id': 'profile-1',
  'technician_name': 'Technician One',
  'parts_required': true,
  'estimated_hours': 1.5,
  'actual_hours': 0,
  'estimated_cost': 180,
  'actual_cost': 0,
  'roadworthy': false,
  'created_at': '2026-09-09T06:05:00.000Z',
  'started_at': null,
  'completed_at': null,
};
