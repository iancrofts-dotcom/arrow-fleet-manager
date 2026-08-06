import 'dart:convert';

/// ============================================================================
/// INSPECTION ITEM STATUS
/// ============================================================================

enum InspectionItemStatus {
  notApplicable,
  pass,
  fail,
  advisory,
}

/// ============================================================================
/// INSPECTION CATEGORY
/// ============================================================================

enum InspectionCategory {
  vehicleInformation,
  exterior,
  bodywork,
  wheelsTyres,
  brakes,
  steering,
  suspension,
  engine,
  transmission,
  electrical,
  interior,
  underbody,
  roadTest,
  signOff,
}

/// ============================================================================
/// INSPECTION ITEM
/// ============================================================================

class InspectionItem {
  final int? id;

  final int inspectionId;

  final InspectionCategory category;

  final String title;

  final InspectionItemStatus status;

  final bool mandatory;

  final bool repairRequired;

  final String notes;

  final int photoCount;

  final int displayOrder;

  const InspectionItem({
    this.id,
    required this.inspectionId,
    required this.category,
    required this.title,
    this.status = InspectionItemStatus.notApplicable,
    this.mandatory = true,
    this.repairRequired = false,
    this.notes = '',
    this.photoCount = 0,
    required this.displayOrder,
  });

  InspectionItem copyWith({
    int? id,
    int? inspectionId,
    InspectionCategory? category,
    String? title,
    InspectionItemStatus? status,
    bool? mandatory,
    bool? repairRequired,
    String? notes,
    int? photoCount,
    int? displayOrder,
  }) {
    return InspectionItem(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      category: category ?? this.category,
      title: title ?? this.title,
      status: status ?? this.status,
      mandatory: mandatory ?? this.mandatory,
      repairRequired: repairRequired ?? this.repairRequired,
      notes: notes ?? this.notes,
      photoCount: photoCount ?? this.photoCount,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionId': inspectionId,
      'category': category.name,
      'title': title,
      'status': status.name,
      'mandatory': mandatory ? 1 : 0,
      'repairRequired': repairRequired ? 1 : 0,
      'notes': notes,
      'photoCount': photoCount,
      'displayOrder': displayOrder,
    };
  }

  factory InspectionItem.fromMap(Map<String, dynamic> map) {
    return InspectionItem(
      id: map['id'],
      inspectionId: map['inspectionId'],
      category: InspectionCategory.values.firstWhere(
        (e) => e.name == map['category'],
      ),
      title: map['title'],
      status: InspectionItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      mandatory: map['mandatory'] == 1,
      repairRequired: map['repairRequired'] == 1,
      notes: map['notes'] ?? '',
      photoCount: map['photoCount'] ?? 0,
      displayOrder: map['displayOrder'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory InspectionItem.fromJson(String source) =>
      InspectionItem.fromMap(jsonDecode(source));
}