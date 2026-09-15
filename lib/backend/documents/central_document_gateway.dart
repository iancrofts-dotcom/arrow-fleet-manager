import 'dart:typed_data';

abstract interface class CentralDocumentGateway {
  Future<List<Map<String, dynamic>>> listDocuments();

  Future<String> uploadDocument({
    required String entityType,
    required String entityId,
    required String title,
    required String category,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    DateTime? expiresOn,
    String caption,
  });

  Future<String> createSignedUrl(String storagePath);
  Future<Uint8List> downloadDocument(String storagePath);
  Future<void> archiveDocument(String documentId);
}
