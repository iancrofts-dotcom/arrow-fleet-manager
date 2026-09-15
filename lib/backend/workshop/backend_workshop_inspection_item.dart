class BackendWorkshopInspectionItem {
  const BackendWorkshopInspectionItem({
    required this.id,
    required this.inspectionId,
    required this.category,
    required this.title,
    required this.responseType,
    required this.status,
    required this.mandatory,
    required this.repairRequired,
    required this.notes,
    required this.photoCount,
    required this.displayOrder,
    this.legacyId,
    this.sectionTitle,
    this.responseValue,
    this.templateItemId,
    this.criticalSafetyItem = false,
    this.autoCreateRepair = false,
    this.repairPriority = 'medium',
    this.roadworthyImpact = 'none',
    this.photoRequiredOnFail = false,
    this.allowNotes = true,
  });

  final String id;
  final int? legacyId;
  final String inspectionId;
  final String category;
  final String? sectionTitle;
  final String title;
  final String responseType;
  final String? responseValue;
  final String status;
  final bool mandatory;
  final bool repairRequired;
  final String notes;
  final int photoCount;
  final int displayOrder;
  final String? templateItemId;
  final bool criticalSafetyItem;
  final bool autoCreateRepair;
  final String repairPriority;
  final String roadworthyImpact;
  final bool photoRequiredOnFail;
  final bool allowNotes;

  factory BackendWorkshopInspectionItem.fromJson(Map<String, dynamic> json) {
    return BackendWorkshopInspectionItem(
      id: json['id'] as String,
      legacyId: json['legacy_id'] as int?,
      inspectionId: json['inspection_id'] as String,
      category: json['category'] as String,
      sectionTitle: json['section_title'] as String?,
      title: json['title'] as String,
      responseType: json['response_type'] as String,
      responseValue: json['response_value'] as String?,
      status: json['status'] as String,
      mandatory: json['mandatory'] as bool? ?? true,
      repairRequired: json['repair_required'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
      displayOrder: (json['display_order'] as num).toInt(),
      templateItemId: json['template_item_id'] as String?,
      criticalSafetyItem: json['critical_safety_item'] as bool? ?? false,
      autoCreateRepair: json['auto_create_repair'] as bool? ?? false,
      repairPriority: json['repair_priority'] as String? ?? 'medium',
      roadworthyImpact: json['roadworthy_impact'] as String? ?? 'none',
      photoRequiredOnFail: json['photo_required_on_fail'] as bool? ?? false,
      allowNotes: json['allow_notes'] as bool? ?? true,
    );
  }
}
