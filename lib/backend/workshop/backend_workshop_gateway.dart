import 'dart:typed_data';

abstract interface class BackendWorkshopGateway {
  Future<List<Map<String, dynamic>>> listInspections();
  Future<Map<String, dynamic>?> getInspection(String id);
  Future<List<Map<String, dynamic>>> listInspectionItems(String inspectionId);
  Future<List<Map<String, dynamic>>> listRepairJobs({String? inspectionId});
  Future<List<Map<String, dynamic>>> listTechnicians();
  Future<List<Map<String, dynamic>>> listTemplates();
  Future<List<Map<String, dynamic>>> listTemplateItems(String templateId);
  Future<List<Map<String, dynamic>>> listEvidence(String inspectionItemId);
  Future<List<Map<String, dynamic>>> listDocuments();
  Future<String> createInspection(Map<String, dynamic> values);
  Future<String> createInspectionFromTemplate(Map<String, dynamic> values);
  Future<String> saveInspectionItem(Map<String, dynamic> values);
  Future<String> createRepairJob(Map<String, dynamic> values);
  Future<void> updateRepairJob(String id, Map<String, dynamic> values);
  Future<void> assignInspectionTechnician(
    String inspectionId,
    String? technicianProfileId,
  );
  Future<void> assignRepairTechnician(
    String repairJobId,
    String? technicianProfileId,
  );
  Future<void> completeInspection(String inspectionId);
  Future<void> signOffInspection(String inspectionId);
  Future<void> uploadInspectionEvidence({
    required String inspectionId,
    required String inspectionItemId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    String caption,
  });
  Future<String> createEvidenceSignedUrl(String storagePath);
}

abstract interface class BackendWorkshopRepairSignOffGateway {
  Future<void> signOffRepairJob(String id, Map<String, dynamic> values);
}

abstract interface class BackendWorkshopTemplateWriteGateway {
  Future<String> saveTemplate(Map<String, dynamic> values);
}

abstract interface class BackendWorkshopEvidenceDownloadGateway {
  Future<Uint8List> downloadEvidence(String storagePath);
}
