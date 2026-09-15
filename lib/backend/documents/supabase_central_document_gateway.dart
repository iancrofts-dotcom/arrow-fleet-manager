import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend_client.dart';
import '../organisation/central_organisation_service.dart';
import '../resilience/central_cached_read.dart';
import '../resilience/central_emergency_operation_catalog.dart';
import '../resilience/central_resilient_mutation_executor.dart';
import 'central_document_gateway.dart';

class SupabaseCentralDocumentGateway implements CentralDocumentGateway {
  const SupabaseCentralDocumentGateway({CentralCachedRead? cachedRead})
    : _cachedReadOverride = cachedRead;

  final CentralCachedRead? _cachedReadOverride;
  CentralCachedRead get _cachedRead =>
      _cachedReadOverride ?? CentralCachedRead();

  static const _columns =
      'id, entity_type, entity_id, category, title, inspection_id, inspection_item_id, vehicle_id, driver_id, file_name, storage_path, content_type, size_bytes, caption, expires_on, uploader_name, created_at, archived_at';

  @override
  Future<List<Map<String, dynamic>>> listDocuments() => _cachedRead.list(
    cacheKey: 'documents:list',
    operation: () async =>
        (await BackendClient.client
                .from('fleet_documents')
                .select(_columns)
                .order('created_at', ascending: false))
            .cast<Map<String, dynamic>>(),
  );

  @override
  Future<String> uploadDocument({
    required String entityType,
    required String entityId,
    required String title,
    required String category,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    DateTime? expiresOn,
    String caption = '',
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final token =
        '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}';
    final organisationId = await CentralOrganisationService.instance
        .currentOrganisationId();
    final storagePath =
        '$organisationId/$entityType/$entityId/$token-$safeName';
    await BackendClient.client.storage
        .from('fleet-documents')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    try {
      final id = await BackendClient.client.rpc(
        'fleet_register_document',
        params: {
          'p_entity_type': entityType,
          'p_entity_id': entityId,
          'p_category': category,
          'p_title': title,
          'p_file_name': fileName,
          'p_storage_path': storagePath,
          'p_content_type': contentType,
          'p_size_bytes': bytes.length,
          'p_expires_on': expiresOn == null ? null : _date(expiresOn),
          'p_caption': caption,
        },
      );
      return id as String;
    } catch (_) {
      await BackendClient.client.storage.from('fleet-documents').remove([
        storagePath,
      ]);
      rethrow;
    }
  }

  @override
  Future<String> createSignedUrl(String storagePath) => BackendClient
      .client
      .storage
      .from('fleet-documents')
      .createSignedUrl(storagePath, 300);

  @override
  Future<Uint8List> downloadDocument(String storagePath) => BackendClient
      .client
      .storage
      .from('fleet-documents')
      .download(storagePath);

  @override
  Future<void> archiveDocument(String documentId) =>
      CentralResilientMutationExecutor.instance.executeVoid(
        operation: CentralEmergencyOperationCatalog.documentArchive,
        payload: <String, dynamic>{'document_id': documentId},
      );
}

String _date(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
