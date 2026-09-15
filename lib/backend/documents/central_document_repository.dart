import 'dart:typed_data';

import 'backend_fleet_document.dart';
import 'central_document_gateway.dart';

class CentralDocumentRepository {
  const CentralDocumentRepository(this._gateway);

  final CentralDocumentGateway _gateway;

  Future<List<BackendFleetDocument>> listDocuments({
    bool includeArchived = false,
  }) async {
    final documents = (await _gateway.listDocuments())
        .map(BackendFleetDocument.fromJson)
        .toList(growable: false);
    return includeArchived
        ? documents
        : documents
              .where((document) => !document.isArchived)
              .toList(growable: false);
  }

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
  }) => _gateway.uploadDocument(
    entityType: entityType,
    entityId: entityId,
    title: title,
    category: category,
    fileName: fileName,
    bytes: bytes,
    contentType: contentType,
    expiresOn: expiresOn,
    caption: caption,
  );

  Future<String> createSignedUrl(String storagePath) =>
      _gateway.createSignedUrl(storagePath);

  Future<Uint8List> downloadDocument(String storagePath) =>
      _gateway.downloadDocument(storagePath);

  Future<void> archiveDocument(String documentId) =>
      _gateway.archiveDocument(documentId);
}
