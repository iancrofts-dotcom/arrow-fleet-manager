enum InspectionStatus {
  pass,
  fail,
  notApplicable,
}

class InspectionItem {
  /// Unique identifier for persistence
  final String id;

  /// Display name
  final String title;

  /// Inspection section
  final String category;

  /// Current inspection result
  InspectionStatus status;

  /// Inspector notes
  String notes;

  InspectionItem({
    required this.id,
    required this.title,
    required this.category,
    this.status = InspectionStatus.pass,
    this.notes = '',
  });

  bool get hasFailed => status == InspectionStatus.fail;

  bool get hasPassed => status == InspectionStatus.pass;

  bool get isNotApplicable =>
      status == InspectionStatus.notApplicable;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'status': status.name,
      'notes': notes,
    };
  }

  factory InspectionItem.fromMap(
    Map<String, dynamic> map,
  ) {
    return InspectionItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      status: InspectionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InspectionStatus.pass,
      ),
      notes: map['notes'] as String? ?? '',
    );
  }

  InspectionItem copyWith({
    String? id,
    String? title,
    String? category,
    InspectionStatus? status,
    String? notes,
  }) {
    return InspectionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}