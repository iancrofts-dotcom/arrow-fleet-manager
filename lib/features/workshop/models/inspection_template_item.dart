import 'dart:convert';

import 'inspection_item.dart';

/// ============================================================================
/// INSPECTION TEMPLATE ITEM
/// ============================================================================

class InspectionTemplateItem {
  final int? id;

  /// Parent template
  final int templateId;

  /// Display section (Brakes, Engine, etc.)
  final InspectionCategory category;

  /// Inspection item title
  final String title;

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
    required this.category,
    required this.title,
    this.description = '',
    required this.displayOrder,
    this.mandatory = true,
    this.criticalSafetyItem = false,
    this.autoCreateRepair = true,
    this.photoRequiredOnFail = false,
    this.allowNotes = true,
    this.defaultStatus = InspectionItemStatus.notApplicable,
    this.isActive = true,
  });

  InspectionTemplateItem copyWith({
    int? id,
    int? templateId,
    InspectionCategory? category,
    String? title,
    String? description,
    int? displayOrder,
    bool? mandatory,
    bool? criticalSafetyItem,
    bool? autoCreateRepair,
    bool? photoRequiredOnFail,
    bool? allowNotes,
    InspectionItemStatus? defaultStatus,
    bool? isActive,
  }) {
    return InspectionTemplateItem(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      displayOrder: displayOrder ?? this.displayOrder,
      mandatory: mandatory ?? this.mandatory,
      criticalSafetyItem:
          criticalSafetyItem ?? this.criticalSafetyItem,
      autoCreateRepair:
          autoCreateRepair ?? this.autoCreateRepair,
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
      'category': category.name,
      'title': title,
      'description': description,
      'displayOrder': displayOrder,
      'mandatory': mandatory ? 1 : 0,
      'criticalSafetyItem': criticalSafetyItem ? 1 : 0,
      'autoCreateRepair': autoCreateRepair ? 1 : 0,
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
      category: InspectionCategory.values.firstWhere(
        (e) => e.name == map['category'],
      ),
      title: map['title'],
      description: map['description'] ?? '',
      displayOrder: map['displayOrder'],
      mandatory: map['mandatory'] == 1,
      criticalSafetyItem:
          map['criticalSafetyItem'] == 1,
      autoCreateRepair:
          map['autoCreateRepair'] == 1,
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