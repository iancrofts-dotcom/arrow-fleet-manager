import 'dart:convert';

import 'inspection_item.dart';
import 'repair_job.dart';

enum TemplateRoadworthyImpact {
  none,
  advisory,
  notRoadworthy,
}

/// ============================================================================
/// INSPECTION TEMPLATE ITEM
/// ============================================================================

class InspectionTemplateItem {
  final int? id;

  /// Parent template
  final int templateId;

  final int? sectionId;

  /// Display section (Brakes, Engine, etc.)
  final InspectionCategory category;

  /// Inspection item title
  final String title;

  final InspectionResponseType responseType;

  /// Help text shown to technician
  final String description;

  /// Order displayed in the inspection
  final int displayOrder;

  /// Must be completed before inspection can finish
  final bool mandatory;

  /// If failed, vehicle automatically becomes not roadworthy
  final bool criticalSafetyItem;

  /// Automatically create repair job when failed
  final bool autoCreateRepair;

  final RepairPriority repairPriority;

  final TemplateRoadworthyImpact roadworthyImpact;

  /// Require photograph when failed
  final bool photoRequiredOnFail;

  /// Allow technician notes
  final bool allowNotes;

  /// Default inspection status (normally N/A)
  final InspectionItemStatus defaultStatus;

  /// Enabled in this template
  final bool isActive;

  const InspectionTemplateItem({
    this.id,
    required this.templateId,
    this.sectionId,
    required this.category,
    required this.title,
    this.responseType = InspectionResponseType.passFailNotApplicable,
    this.description = '',
    required this.displayOrder,
    this.mandatory = true,
    this.criticalSafetyItem = false,
    this.autoCreateRepair = true,
    this.repairPriority = RepairPriority.medium,
    this.roadworthyImpact = TemplateRoadworthyImpact.none,
    this.photoRequiredOnFail = false,
    this.allowNotes = true,
    this.defaultStatus = InspectionItemStatus.notApplicable,
    this.isActive = true,
  });

  InspectionTemplateItem copyWith({
    int? id,
    int? templateId,
    int? sectionId,
    InspectionCategory? category,
    String? title,
    InspectionResponseType? responseType,
    String? description,
    int? displayOrder,
    bool? mandatory,
    bool? criticalSafetyItem,
    bool? autoCreateRepair,
    RepairPriority? repairPriority,
    TemplateRoadworthyImpact? roadworthyImpact,
    bool? photoRequiredOnFail,
    bool? allowNotes,
    InspectionItemStatus? defaultStatus,
    bool? isActive,
  }) {
    return InspectionTemplateItem(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      sectionId: sectionId ?? this.sectionId,
      category: category ?? this.category,
      title: title ?? this.title,
      responseType: responseType ?? this.responseType,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      mandatory: mandatory ?? this.mandatory,
      criticalSafetyItem:
          criticalSafetyItem ?? this.criticalSafetyItem,
      autoCreateRepair:
          autoCreateRepair ?? this.autoCreateRepair,
      repairPriority: repairPriority ?? this.repairPriority,
      roadworthyImpact: roadworthyImpact ?? this.roadworthyImpact,
      photoRequiredOnFail:
          photoRequiredOnFail ?? this.photoRequiredOnFail,
      allowNotes: allowNotes ?? this.allowNotes,
      defaultStatus: defaultStatus ?? this.defaultStatus,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'templateId': templateId,
      'sectionId': sectionId,
      'category': category.name,
      'title': title,
      'responseType': responseType.name,
      'description': description,
      'displayOrder': displayOrder,
      'mandatory': mandatory ? 1 : 0,
      'criticalSafetyItem': criticalSafetyItem ? 1 : 0,
      'autoCreateRepair': autoCreateRepair ? 1 : 0,
      'repairPriority': repairPriority.name,
      'roadworthyImpact': roadworthyImpact.name,
      'photoRequiredOnFail': photoRequiredOnFail ? 1 : 0,
      'allowNotes': allowNotes ? 1 : 0,
      'defaultStatus': defaultStatus.name,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory InspectionTemplateItem.fromMap(
      Map<String, dynamic> map) {
    return InspectionTemplateItem(
      id: map['id'],
      templateId: map['templateId'],
      sectionId: map['sectionId'],
      category: InspectionCategory.values.firstWhere(
        (e) => e.name == map['category'],
      ),
      title: map['title'],
      responseType: InspectionResponseType.values.firstWhere(
        (e) => e.name == map['responseType'],
        orElse: () => InspectionResponseType.passFailNotApplicable,
      ),
      description: map['description'] ?? '',
      displayOrder: map['displayOrder'],
      mandatory: map['mandatory'] == 1,
      criticalSafetyItem:
          map['criticalSafetyItem'] == 1,
      autoCreateRepair:
          map['autoCreateRepair'] == 1,
      repairPriority: RepairPriority.values.firstWhere(
        (e) => e.name == map['repairPriority'],
        orElse: () => RepairPriority.medium,
      ),
      roadworthyImpact: TemplateRoadworthyImpact.values.firstWhere(
        (e) => e.name == map['roadworthyImpact'],
        orElse: () => TemplateRoadworthyImpact.none,
      ),
      photoRequiredOnFail:
          map['photoRequiredOnFail'] == 1,
      allowNotes: map['allowNotes'] == 1,
      defaultStatus:
          InspectionItemStatus.values.firstWhere(
        (e) => e.name == map['defaultStatus'],
      ),
      isActive: map['isActive'] == 1,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory InspectionTemplateItem.fromJson(
    String source,
  ) =>
      InspectionTemplateItem.fromMap(
        jsonDecode(source),
      );
}
