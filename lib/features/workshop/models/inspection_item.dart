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

enum InspectionResponseType {
  passFailNotApplicable,
  yesNoNotApplicable,
  text,
  numeric,
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

  final String? sectionTitle;

  final String title;

  final InspectionResponseType responseType;

  final String? responseValue;

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
    this.sectionTitle,
    required this.title,
    this.responseType = InspectionResponseType.passFailNotApplicable,
    this.responseValue,
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
    String? sectionTitle,
    String? title,
    InspectionResponseType? responseType,
    String? responseValue,
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
      sectionTitle: sectionTitle ?? this.sectionTitle,
      title: title ?? this.title,
      responseType: responseType ?? this.responseType,
      responseValue: responseValue ?? this.responseValue,
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
      'sectionTitle': sectionTitle,
      'title': title,
      'responseType': responseType.name,
      'responseValue': responseValue,
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
      sectionTitle: map['sectionTitle'],
      title: map['title'],
      responseType: InspectionResponseType.values.firstWhere(
        (e) => e.name == map['responseType'],
        orElse: () => InspectionResponseType.passFailNotApplicable,
      ),
      responseValue: map['responseValue'],
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
