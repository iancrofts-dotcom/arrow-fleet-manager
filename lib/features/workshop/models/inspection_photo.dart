import 'dart:convert';

/// A photograph attached to a workshop inspection checklist item.
class InspectionPhoto {
  final int? id;
  final int inspectionId;
  final int inspectionItemId;
  final String filePath;
  final DateTime createdAt;

  const InspectionPhoto({
    this.id,
    required this.inspectionId,
    required this.inspectionItemId,
    required this.filePath,
    required this.createdAt,
  });

  InspectionPhoto copyWith({
    int? id,
    int? inspectionId,
    int? inspectionItemId,
    String? filePath,
    DateTime? createdAt,
  }) {
    return InspectionPhoto(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      inspectionItemId:
          inspectionItemId ?? this.inspectionItemId,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionId': inspectionId,
      'inspectionItemId': inspectionItemId,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InspectionPhoto.fromMap(
    Map<String, dynamic> map,
  ) {
    return InspectionPhoto(
      id: map['id'] as int?,
      inspectionId: map['inspectionId'] as int,
      inspectionItemId:
          map['inspectionItemId'] as int,
      filePath: map['filePath'] as String,
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory InspectionPhoto.fromJson(String source) =>
      InspectionPhoto.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
      );
}
