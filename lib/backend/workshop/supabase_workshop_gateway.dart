import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend_client.dart';
import '../organisation/central_organisation_service.dart';
import '../resilience/central_cached_read.dart';
import '../resilience/central_emergency_operation_catalog.dart';
import '../resilience/central_resilient_mutation_executor.dart';
import 'backend_workshop_gateway.dart';

class SupabaseWorkshopGateway
    implements
        BackendWorkshopGateway,
        BackendWorkshopRepairSignOffGateway,
        BackendWorkshopTemplateWriteGateway,
        BackendWorkshopEvidenceDownloadGateway {
  const SupabaseWorkshopGateway({CentralCachedRead? cachedRead})
    : _cachedReadOverride = cachedRead;

  final CentralCachedRead? _cachedReadOverride;
  CentralCachedRead get _cachedRead =>
      _cachedReadOverride ?? CentralCachedRead();

  static const _inspectionColumns =
      'id, legacy_id, inspection_number, vehicle_id, registration, fleet_number, template_id, template_name, technician_profile_id, technician_name, driver_id, driver_name, workshop_manager, inspection_type, status, vehicle_status, date_started, date_completed, mileage, overall_result, inspection_score, critical_failures, advisories, repairs_required, labour_hours, total_cost, notes, created_at, updated_at';
  static const _itemColumns =
      'id, legacy_id, inspection_id, template_item_id, category, section_title, title, response_type, response_value, status, mandatory, repair_required, notes, photo_count, display_order, critical_safety_item, auto_create_repair, repair_priority, roadworthy_impact, photo_required_on_fail, allow_notes';
  static const _repairColumns =
      'id, legacy_id, job_number, inspection_id, inspection_item_id, vehicle_id, vehicle_registration, title, description, priority, status, technician_profile_id, technician_name, parts_required, estimated_hours, actual_hours, estimated_cost, actual_cost, roadworthy, created_at, started_at, completed_at, work_notes, parts_notes, signed_off_by, signed_off_name, signed_off_at, technician_mileage';
  static const _templateColumns =
      'id, name, description, inspection_type, template_version, is_default, is_active';
  static const _templateItemColumns =
      'id, template_id, section_title, category, title, description, response_type, mandatory, critical_safety_item, auto_create_repair, repair_priority, roadworthy_impact, photo_required_on_fail, allow_notes, default_status, display_order';
  static const _documentColumns =
      'id, entity_type, entity_id, category, inspection_id, inspection_item_id, vehicle_id, driver_id, file_name, storage_path, content_type, size_bytes, caption, expires_on, uploader_name, created_at';

  @override
  Future<List<Map<String, dynamic>>> listInspections() => _cachedRead.list(
    cacheKey: 'workshop:inspections:list',
    operation: () async =>
        (await BackendClient.client
                .from('workshop_inspections')
                .select(_inspectionColumns)
                .order('date_started', ascending: false))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<Map<String, dynamic>?> getInspection(String id) =>
      _cachedRead.maybeSingle(
        cacheKey: 'workshop:inspections:item:$id',
        operation: () => BackendClient.client
            .from('workshop_inspections')
            .select(_inspectionColumns)
            .eq('id', id)
            .maybeSingle(),
      );

  @override
  Future<List<Map<String, dynamic>>> listInspectionItems(String inspectionId) =>
      _cachedRead.list(
        cacheKey: 'workshop:inspection_items:$inspectionId',
        operation: () async =>
            (await BackendClient.client
                    .from('workshop_inspection_items')
                    .select(_itemColumns)
                    .eq('inspection_id', inspectionId)
                    .order('display_order'))
                .cast<Map<String, dynamic>>(),
      );

  @override
  Future<List<Map<String, dynamic>>> listRepairJobs({String? inspectionId}) =>
      _cachedRead.list(
        cacheKey: inspectionId == null
            ? 'workshop:repairs:list'
            : 'workshop:repairs:inspection:$inspectionId',
        operation: () async {
          final query = BackendClient.client
              .from('workshop_repair_jobs')
              .select(_repairColumns);
          final rows = inspectionId == null
              ? await query.order('created_at', ascending: false)
              : await query
                    .eq('inspection_id', inspectionId)
                    .order('created_at', ascending: false);
          return rows.cast<Map<String, dynamic>>();
        },
      );

  @override
  Future<List<Map<String, dynamic>>> listTechnicians() => _cachedRead.list(
    cacheKey: 'workshop:technicians:list',
    operation: () async => (await BackendClient.client.rpc(
      'workshop_list_technicians',
    )).cast<Map<String, dynamic>>(),
  );

  @override
  Future<List<Map<String, dynamic>>> listTemplates() => _cachedRead.list(
    cacheKey: 'workshop:templates:list',
    operation: () async =>
        (await BackendClient.client
                .from('workshop_inspection_templates')
                .select(_templateColumns)
                .eq('is_active', true)
                .order('is_default', ascending: false)
                .order('name'))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<List<Map<String, dynamic>>> listTemplateItems(String templateId) =>
      _cachedRead.list(
        cacheKey: 'workshop:template_items:$templateId',
        operation: () async =>
            (await BackendClient.client
                    .from('workshop_inspection_template_items')
                    .select(_templateItemColumns)
                    .eq('template_id', templateId)
                    .order('display_order'))
                .cast<Map<String, dynamic>>(),
      );

  @override
  Future<List<Map<String, dynamic>>> listEvidence(String inspectionItemId) =>
      _cachedRead.list(
        cacheKey: 'workshop:evidence:$inspectionItemId',
        operation: () async =>
            (await BackendClient.client
                    .from('fleet_documents')
                    .select(_documentColumns)
                    .eq('inspection_item_id', inspectionItemId)
                    .order('created_at', ascending: false))
                .cast<Map<String, dynamic>>(),
      );

  @override
  Future<List<Map<String, dynamic>>> listDocuments() => _cachedRead.list(
    cacheKey: 'workshop:documents:list',
    operation: () async =>
        (await BackendClient.client
                .from('fleet_documents')
                .select(_documentColumns)
                .order('created_at', ascending: false))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<String> createInspection(Map<String, dynamic> values) async =>
      (await BackendClient.client.rpc(
            'workshop_create_inspection',
            params: {
              'p_vehicle_id': values['vehicle_id'],
              'p_inspection_type': values['inspection_type'],
              'p_mileage': values['mileage'],
              'p_notes': values['notes'],
              'p_technician_profile_id': values['technician_profile_id'],
            },
          ))
          as String;

  @override
  Future<String> createInspectionFromTemplate(
    Map<String, dynamic> values,
  ) async =>
      (await BackendClient.client.rpc(
            'workshop_create_inspection_from_template',
            params: {
              'p_vehicle_id': values['vehicle_id'],
              'p_template_id': values['template_id'],
              'p_inspection_type': values['inspection_type'],
              'p_mileage': values['mileage'],
              'p_notes': values['notes'],
              'p_technician_profile_id': values['technician_profile_id'],
            },
          ))
          as String;

  @override
  Future<String> saveInspectionItem(Map<String, dynamic> values) =>
      CentralResilientMutationExecutor.instance.executeString(
        operation: CentralEmergencyOperationCatalog.workshopSaveInspectionItem,
        payload: Map<String, dynamic>.from(values),
        queuedValue: values['id'] as String,
      );

  @override
  Future<String> createRepairJob(Map<String, dynamic> values) async =>
      (await BackendClient.client.rpc(
            'workshop_create_repair_job',
            params: {
              'p_inspection_id': values['inspection_id'],
              'p_inspection_item_id': values['inspection_item_id'],
              'p_title': values['title'],
              'p_description': values['description'],
              'p_priority': values['priority'],
              'p_technician_profile_id': values['technician_profile_id'],
              'p_parts_required': values['parts_required'],
              'p_estimated_hours': values['estimated_hours'],
              'p_estimated_cost': values['estimated_cost'],
            },
          ))
          as String;

  @override
  Future<void> updateRepairJob(String id, Map<String, dynamic> values) =>
      CentralResilientMutationExecutor.instance.executeVoid(
        operation: CentralEmergencyOperationCatalog.workshopUpdateRepairJob,
        payload: <String, dynamic>{'id': id, ...values},
      );

  @override
  Future<void> signOffRepairJob(String id, Map<String, dynamic> values) =>
      CentralResilientMutationExecutor.instance.executeVoid(
        operation: CentralEmergencyOperationCatalog.workshopSignOffRepairJob,
        payload: <String, dynamic>{'id': id, ...values},
      );

  @override
  Future<String> saveTemplate(Map<String, dynamic> values) async =>
      (await BackendClient.client.rpc(
            'workshop_save_template',
            params: {
              'p_template_id': values['id'],
              'p_name': values['name'],
              'p_description': values['description'],
              'p_inspection_type': values['inspection_type'],
              'p_is_active': values['is_active'],
              'p_items': values['items'],
            },
          ))
          as String;

  @override
  Future<void> assignInspectionTechnician(
    String inspectionId,
    String? technicianProfileId,
  ) => CentralResilientMutationExecutor.instance.executeVoid(
    operation:
        CentralEmergencyOperationCatalog.workshopAssignInspectionTechnician,
    payload: <String, dynamic>{
      'inspection_id': inspectionId,
      'technician_profile_id': technicianProfileId,
    },
  );

  @override
  Future<void> assignRepairTechnician(
    String repairJobId,
    String? technicianProfileId,
  ) => CentralResilientMutationExecutor.instance.executeVoid(
    operation: CentralEmergencyOperationCatalog.workshopAssignRepairTechnician,
    payload: <String, dynamic>{
      'repair_job_id': repairJobId,
      'technician_profile_id': technicianProfileId,
    },
  );

  @override
  Future<void> completeInspection(String inspectionId) =>
      CentralResilientMutationExecutor.instance.executeVoid(
        operation: CentralEmergencyOperationCatalog.workshopCompleteInspection,
        payload: <String, dynamic>{'inspection_id': inspectionId},
      );

  @override
  Future<void> signOffInspection(String inspectionId) =>
      CentralResilientMutationExecutor.instance.executeVoid(
        operation: CentralEmergencyOperationCatalog.workshopSignOffInspection,
        payload: <String, dynamic>{'inspection_id': inspectionId},
      );

  @override
  Future<void> uploadInspectionEvidence({
    required String inspectionId,
    required String inspectionItemId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    String caption = '',
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final organisationId = await CentralOrganisationService.instance
        .currentOrganisationId();
    final storagePath =
        '$organisationId/workshop/$inspectionId/$inspectionItemId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final storage = BackendClient.client.storage.from('fleet-documents');
    await storage.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    try {
      await BackendClient.client.rpc(
        'workshop_register_evidence',
        params: {
          'p_inspection_id': inspectionId,
          'p_inspection_item_id': inspectionItemId,
          'p_file_name': fileName,
          'p_storage_path': storagePath,
          'p_content_type': contentType,
          'p_size_bytes': bytes.length,
          'p_caption': caption,
        },
      );
    } catch (_) {
      await storage.remove([storagePath]);
      rethrow;
    }
  }

  @override
  Future<String> createEvidenceSignedUrl(String storagePath) => BackendClient
      .client
      .storage
      .from('fleet-documents')
      .createSignedUrl(storagePath, 900);

  @override
  Future<Uint8List> downloadEvidence(String storagePath) => BackendClient
      .client
      .storage
      .from('fleet-documents')
      .download(storagePath);
}
