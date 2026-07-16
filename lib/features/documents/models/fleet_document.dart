class FleetDocument {
  const FleetDocument({
    this.id,
    required this.title,
    required this.category,
    required this.filePath,
    required this.issueDate,
    required this.expiryDate,
    required this.lastUpdated,
    this.notes,
    this.driverId,
    this.vehicleId,
  });

  final int? id;
  final String title;
  final DocumentCategory category;
  final String filePath;

  final DateTime issueDate;
  final DateTime expiryDate;
  final DateTime lastUpdated;

  final String? notes;

  final int? driverId;
  final int? vehicleId;

  bool get isExpired =>
      expiryDate.isBefore(DateTime.now());

  bool get isDueSoon =>
      !isExpired &&
      expiryDate
              .difference(DateTime.now())
              .inDays <=
          30;

  int get daysRemaining =>
      expiryDate
          .difference(DateTime.now())
          .inDays;

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'filePath': filePath,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate':
          expiryDate.toIso8601String(),
      'lastUpdated':
          lastUpdated.toIso8601String(),
      'notes': notes,
      'driverId': driverId,
      'vehicleId': vehicleId,
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
      ),
      filePath: map['filePath'] as String,
      issueDate: DateTime.parse(
        map['issueDate'] as String,
      ),
      expiryDate: DateTime.parse(
        map['expiryDate'] as String,
      ),
      lastUpdated: DateTime.parse(
        map['lastUpdated'] as String,
      ),
      notes: map['notes'] as String?,
      driverId: map['driverId'] as int?,
      vehicleId: map['vehicleId'] as int?,
    );
  }
}

enum DocumentCategory {
  licence,
  cpc,
  medical,
  insurance,
  mot,
  v5,
  service,
  inspection,
  policy,
  other,
}