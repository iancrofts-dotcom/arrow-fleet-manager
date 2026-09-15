class BackendFleetDocument {
  const BackendFleetDocument({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.category,
    required this.fileName,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    required this.createdAt,
    required this.uploaderName,
    this.expiresOn,
    this.caption = '',
    this.title = '',
    this.archivedAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String category;
  final String fileName;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final DateTime createdAt;
  final String uploaderName;
  final DateTime? expiresOn;
  final String caption;
  final String title;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  factory BackendFleetDocument.fromJson(Map<String, dynamic> json) {
    return BackendFleetDocument(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      category: json['category'] as String,
      fileName: json['file_name'] as String,
      storagePath: json['storage_path'] as String,
      contentType:
          json['content_type'] as String? ?? 'application/octet-stream',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      uploaderName: json['uploader_name'] as String? ?? '',
      expiresOn: json['expires_on'] == null
          ? null
          : DateTime.parse(json['expires_on'] as String),
      caption: json['caption'] as String? ?? '',
      title: json['title'] as String? ?? '',
      archivedAt: json['archived_at'] == null
          ? null
          : DateTime.parse(json['archived_at'] as String),
    );
  }
}
