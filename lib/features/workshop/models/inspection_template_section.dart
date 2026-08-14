class InspectionTemplateSection {
  final int? id;
  final int templateId;
  final String title;
  final int displayOrder;

  const InspectionTemplateSection({
    this.id,
    required this.templateId,
    required this.title,
    required this.displayOrder,
  });

  InspectionTemplateSection copyWith({
    int? id,
    int? templateId,
    String? title,
    int? displayOrder,
  }) {
    return InspectionTemplateSection(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'templateId': templateId,
        'title': title,
        'displayOrder': displayOrder,
      };

  factory InspectionTemplateSection.fromMap(Map<String, dynamic> map) {
    return InspectionTemplateSection(
      id: map['id'] as int?,
      templateId: map['templateId'] as int,
      title: map['title'] as String,
      displayOrder: map['displayOrder'] as int,
    );
  }
}
