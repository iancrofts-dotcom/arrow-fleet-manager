class BackendWorkshopEvidence {
  const BackendWorkshopEvidence({
    required this.id,
    required this.inspectionId,
    required this.inspectionItemId,
    required this.fileName,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    required this.caption,
    required this.createdAt,
    required this.uploaderName,
  });

  final String id;
  final String inspectionId;
  final String inspectionItemId;
  final String fileName;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final String caption;
  final DateTime createdAt;
  final String uploaderName;

  factory BackendWorkshopEvidence.fromJson(Map<String, dynamic> json) {
    return BackendWorkshopEvidence(
      id: json['id'] as String,
      inspectionId: json['inspection_id'] as String,
      inspectionItemId: json['inspection_item_id'] as String,
      fileName: json['file_name'] as String,
      storagePath: json['storage_path'] as String,
      contentType:
          json['content_type'] as String? ?? 'application/octet-stream',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      caption: json['caption'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      uploaderName: json['uploader_name'] as String? ?? '',
    );
  }
}
