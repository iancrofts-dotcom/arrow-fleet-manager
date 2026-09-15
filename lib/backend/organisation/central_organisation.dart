class CentralOrganisation {
  const CentralOrganisation({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.isCurrent,
  });

  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final bool isCurrent;

  factory CentralOrganisation.fromJson(Map<String, dynamic> json) =>
      CentralOrganisation(
        id: json['id'] as String,
        name: (json['name'] as String?)?.trim() ?? '',
        slug: (json['slug'] as String?)?.trim() ?? '',
        isActive: json['is_active'] as bool? ?? true,
        isCurrent: json['is_current'] as bool? ?? false,
      );
}
