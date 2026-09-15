class BackendWorkshopTemplate {
  const BackendWorkshopTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.inspectionType,
    required this.version,
    required this.isDefault,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final String? inspectionType;
  final int version;
  final bool isDefault;
  final bool isActive;

  factory BackendWorkshopTemplate.fromJson(Map<String, dynamic> json) {
    return BackendWorkshopTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      inspectionType: json['inspection_type'] as String?,
      version: (json['template_version'] as num?)?.toInt() ?? 1,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class BackendWorkshopTemplateItem {
  const BackendWorkshopTemplateItem({
    required this.id,
    required this.templateId,
    required this.category,
    required this.title,
    required this.responseType,
    required this.mandatory,
    required this.criticalSafetyItem,
    required this.autoCreateRepair,
    required this.repairPriority,
    required this.roadworthyImpact,
    required this.photoRequiredOnFail,
    required this.allowNotes,
    required this.defaultStatus,
    required this.displayOrder,
    this.sectionTitle,
    this.description = '',
  });

  final String id;
  final String templateId;
  final String category;
  final String? sectionTitle;
  final String title;
  final String description;
  final String responseType;
  final bool mandatory;
  final bool criticalSafetyItem;
  final bool autoCreateRepair;
  final String repairPriority;
  final String roadworthyImpact;
  final bool photoRequiredOnFail;
  final bool allowNotes;
  final String defaultStatus;
  final int displayOrder;

  factory BackendWorkshopTemplateItem.fromJson(Map<String, dynamic> json) {
    return BackendWorkshopTemplateItem(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      category: json['category'] as String,
      sectionTitle: json['section_title'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      responseType: json['response_type'] as String? ?? 'passFailNotApplicable',
      mandatory: json['mandatory'] as bool? ?? true,
      criticalSafetyItem: json['critical_safety_item'] as bool? ?? false,
      autoCreateRepair: json['auto_create_repair'] as bool? ?? true,
      repairPriority: json['repair_priority'] as String? ?? 'medium',
      roadworthyImpact: json['roadworthy_impact'] as String? ?? 'none',
      photoRequiredOnFail: json['photo_required_on_fail'] as bool? ?? false,
      allowNotes: json['allow_notes'] as bool? ?? true,
      defaultStatus: json['default_status'] as String? ?? 'notApplicable',
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}
