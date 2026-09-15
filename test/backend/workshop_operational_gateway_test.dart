import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import 'package:arrow_fleet_manager/backend/workshop/backend_workshop_gateway.dart';
import 'package:arrow_fleet_manager/backend/workshop/backend_workshop_repository.dart';
import 'package:arrow_fleet_manager/backend/workshop/backend_workshop_writes.dart';

class _Gateway implements BackendWorkshopGateway {
  final calls = <String>[];
  @override
  Future<List<Map<String, dynamic>>> listInspections() async => [];
  @override
  Future<Map<String, dynamic>?> getInspection(String id) async => null;
  @override
  Future<List<Map<String, dynamic>>> listInspectionItems(
    String inspectionId,
  ) async => [];
  @override
  Future<List<Map<String, dynamic>>> listRepairJobs({
    String? inspectionId,
  }) async => [];
  @override
  Future<List<Map<String, dynamic>>> listTechnicians() async => [
    {'id': '00000000-0000-4000-8000-000000000001', 'username': 'Tech One'},
  ];
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
  Future<String> createInspection(Map<String, dynamic> values) async {
    calls.add('create');
    return '00000000-0000-4000-8000-000000000002';
  }

  @override
  Future<String> saveInspectionItem(Map<String, dynamic> values) async {
    calls.add('item:${values['status']}');
    return 'item';
  }

  @override
  Future<String> createRepairJob(Map<String, dynamic> values) async {
    calls.add('repair:${values['priority']}');
    return 'repair';
  }

  @override
  Future<void> updateRepairJob(String id, Map<String, dynamic> values) async {
    calls.add('update:${values['status']}');
  }

  @override
  Future<void> assignInspectionTechnician(
    String inspectionId,
    String? technicianProfileId,
  ) async {
    calls.add('assignInspection');
  }

  @override
  Future<void> assignRepairTechnician(
    String repairJobId,
    String? technicianProfileId,
  ) async {
    calls.add('assignRepair');
  }

  @override
  Future<void> completeInspection(String inspectionId) async {
    calls.add('complete');
  }

  @override
  Future<void> signOffInspection(String inspectionId) async {
    calls.add('signOff');
  }
}

void main() {
  test('repository exposes operational workshop commands', () async {
    final gateway = _Gateway();
    final repository = BackendWorkshopRepository(gateway);
    final technicians = await repository.listTechnicians();
    expect(technicians.single.username, 'Tech One');

    await repository.saveInspectionItem(
      const BackendWorkshopInspectionItemWrite(
        inspectionId: 'inspection',
        category: 'Brakes',
        title: 'Pads',
        status: 'fail',
        repairRequired: true,
      ),
    );
    await repository.createRepairJob(
      const BackendWorkshopRepairJobCreate(
        inspectionId: 'inspection',
        title: 'Replace pads',
        priority: 'high',
      ),
    );
    await repository.updateRepairJob(
      'repair',
      const BackendWorkshopRepairJobUpdate(
        status: 'completed',
        partsRequired: false,
        actualHours: 1.5,
        actualCost: 120,
        roadworthy: true,
      ),
    );
    await repository.completeInspection('inspection');
    await repository.signOffInspection('inspection');

    expect(
      gateway.calls,
      containsAll([
        'item:fail',
        'repair:high',
        'update:completed',
        'complete',
        'signOff',
      ]),
    );
  });
}
