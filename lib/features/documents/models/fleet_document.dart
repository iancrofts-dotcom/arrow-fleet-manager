class FleetDocument {
  const FleetDocument({
    this.id,
    required this.title,
    required this.category,
    required this.filePath,
    required this.issueDate,
    this.expiryDate,
    required this.lastUpdated,
    this.notes,
    this.driverId,
    this.vehicleId,
    this.isArchived = false,
    this.archivedAt,
    this.replacedByDocumentId,
    this.uploadedByUserId,
    this.originalFileName,
  });

  final int? id;
  final String title;
  final DocumentCategory category;
  final String filePath;

  final DateTime issueDate;
  final DateTime? expiryDate;
  final DateTime lastUpdated;

  final String? notes;

  final int? driverId;
  final int? vehicleId;
  final bool isArchived;
  final DateTime? archivedAt;
  final int? replacedByDocumentId;
  final String? uploadedByUserId;
  final String? originalFileName;

  bool get isExpired =>
      expiryDate?.isBefore(DateTime.now()) ?? false;

  bool get isDueSoon =>
      !isExpired &&
      (expiryDate?.difference(DateTime.now()).inDays ?? 999999) <= 30;

  int get daysRemaining =>
      expiryDate?.difference(DateTime.now()).inDays ?? 0;

  FleetDocument copyWith({
    int? id,
    String? title,
    DocumentCategory? category,
    String? filePath,
    DateTime? issueDate,
    DateTime? expiryDate,
    DateTime? lastUpdated,
    String? notes,
    int? driverId,
    int? vehicleId,
    bool? isArchived,
    DateTime? archivedAt,
    int? replacedByDocumentId,
    String? uploadedByUserId,
    String? originalFileName,
  }) {
    return FleetDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      lastUpdated:
          lastUpdated ?? this.lastUpdated,
      notes: notes ?? this.notes,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      replacedByDocumentId:
          replacedByDocumentId ?? this.replacedByDocumentId,
      uploadedByUserId: uploadedByUserId ?? this.uploadedByUserId,
      originalFileName: originalFileName ?? this.originalFileName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'filePath': filePath,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'lastUpdated':
          lastUpdated.toIso8601String(),
      'notes': notes,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'isArchived': isArchived ? 1 : 0,
      'archivedAt': archivedAt?.toIso8601String(),
      'replacedByDocumentId': replacedByDocumentId,
      'uploadedByUserId': uploadedByUserId,
      'originalFileName': originalFileName,
    };
  }

  factory FleetDocument.fromMap(
    Map<String, dynamic> map,
  ) {
    return FleetDocument(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: DocumentCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => DocumentCategory.other,
      ),
      filePath: map['filePath'] as String,
      issueDate: DateTime.parse(
        map['issueDate'] as String,
      ),
      expiryDate: map['expiryDate'] == null
          ? null
          : DateTime.parse(map['expiryDate'] as String),
      lastUpdated: DateTime.parse(
        map['lastUpdated'] as String,
      ),
      notes: map['notes'] as String?,
      driverId: map['driverId'] as int?,
      vehicleId: map['vehicleId'] as int?,
      isArchived: (map['isArchived'] ?? 0) == 1,
      archivedAt: map['archivedAt'] == null
          ? null
          : DateTime.parse(map['archivedAt'] as String),
      replacedByDocumentId: map['replacedByDocumentId'] as int?,
      uploadedByUserId: map['uploadedByUserId'] as String?,
      originalFileName: map['originalFileName'] as String?,
    );
  }
}

enum DocumentCategory {
  licence,
  cpc,
  medical,
  dbs,
  tachographCard,
  insurance,
  mot,
  v5,
  service,
  inspection,
  policy,
  other,
}
