import 'dart:convert';

import 'workshop_inspection.dart';

/// ============================================================================
/// VEHICLE TYPE
/// ============================================================================

enum WorkshopVehicleType { bus, van }

/// ============================================================================
/// INSPECTION TEMPLATE
/// ============================================================================

class InspectionTemplate {
  final int? id;

  final String name;

  final String description;

  final WorkshopVehicleType vehicleType;

  final WorkshopInspectionType? inspectionType;

  final int version;

  final String? sourceReference;

  final bool isDefault;

  final bool isActive;

  final DateTime createdAt;

  final DateTime updatedAt;

  const InspectionTemplate({
    this.id,
    required this.name,
    required this.description,
    required this.vehicleType,
    this.inspectionType,
    this.version = 1,
    this.sourceReference,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  InspectionTemplate copyWith({
    int? id,
    String? name,
    String? description,
    WorkshopVehicleType? vehicleType,
    WorkshopInspectionType? inspectionType,
    int? version,
    String? sourceReference,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InspectionTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      vehicleType: vehicleType ?? this.vehicleType,
      inspectionType: inspectionType ?? this.inspectionType,
      version: version ?? this.version,
      sourceReference: sourceReference ?? this.sourceReference,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'vehicleType': vehicleType.name,
      'inspectionType': inspectionType?.name,
      'templateVersion': version,
      'sourceReference': sourceReference,
      'isDefault': isDefault ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory InspectionTemplate.fromMap(Map<String, dynamic> map) {
    return InspectionTemplate(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      vehicleType: WorkshopVehicleType.values.firstWhere(
        (e) => e.name == map['vehicleType'],
      ),
      inspectionType: map['inspectionType'] == null
          ? null
          : WorkshopInspectionType.values.firstWhere(
              (type) => type.name == map['inspectionType'],
            ),
      version: map['templateVersion'] as int? ?? 1,
      sourceReference: map['sourceReference'] as String?,
      isDefault: map['isDefault'] == 1,
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory InspectionTemplate.fromJson(String source) =>
      InspectionTemplate.fromMap(jsonDecode(source));
}
