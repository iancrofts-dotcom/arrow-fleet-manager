import 'dart:convert';

/// ============================================================================
/// PHOTO TYPE
/// ============================================================================

enum InspectionPhotoType {
  inspection,
  defect,
  repairBefore,
  repairDuring,
  repairAfter,
  completion,
}

/// ============================================================================
/// INSPECTION PHOTO
/// ============================================================================

class InspectionPhoto {
  final int? id;

  final int inspectionId;

  final int? inspectionItemId;

  final String filePath;

  final InspectionPhotoType photoType;

  final String description;

  final DateTime createdAt;

  const InspectionPhoto({
    this.id,
    required this.inspectionId,
    this.inspectionItemId,
    required this.filePath,
    this.photoType = InspectionPhotoType.inspection,
    this.description = '',
    required this.createdAt,
  });

  InspectionPhoto copyWith({
    int? id,
    int? inspectionId,
    int? inspectionItemId,
    String? filePath,
    InspectionPhotoType? photoType,
    String? description,
    DateTime? createdAt,
  }) {
    return InspectionPhoto(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      inspectionItemId: inspectionItemId ?? this.inspectionItemId,
      filePath: filePath ?? this.filePath,
      photoType: photoType ?? this.photoType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionId': inspectionId,
      'inspectionItemId': inspectionItemId,
      'filePath': filePath,
      'photoType': photoType.name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InspectionPhoto.fromMap(Map<String, dynamic> map) {
    return InspectionPhoto(
      id: map['id'],
      inspectionId: map['inspectionId'],
      inspectionItemId: map['inspectionItemId'],
      filePath: map['filePath'],
      photoType: InspectionPhotoType.values.firstWhere(
        (e) => e.name == map['photoType'],
      ),
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory InspectionPhoto.fromJson(String source) =>
      InspectionPhoto.fromMap(jsonDecode(source));
}