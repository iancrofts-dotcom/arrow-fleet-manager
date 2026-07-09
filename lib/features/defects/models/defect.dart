class Defect {
  final int? id;
  final int inspectionId;
  final int? vehicleId;

  final String title;
  final String description;

  final String severity;

  final bool repaired;

  final DateTime reportedDate;

  const Defect({
    this.id,
    required this.inspectionId,
    this.vehicleId,
    required this.title,
    required this.description,
    required this.severity,
    required this.repaired,
    required this.reportedDate,
  });

  Defect copyWith({
    int? id,
    int? inspectionId,
    int? vehicleId,
    String? title,
    String? description,
    String? severity,
    bool? repaired,
    DateTime? reportedDate,
  }) {
    return Defect(
      id: id ?? this.id,
      inspectionId: inspectionId ?? this.inspectionId,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      repaired: repaired ?? this.repaired,
      reportedDate: reportedDate ?? this.reportedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionId': inspectionId,
      'vehicleId': vehicleId,
      'title': title,
      'description': description,
      'severity': severity,
      'repaired': repaired ? 1 : 0,
      'reportedDate': reportedDate.toIso8601String(),
    };
  }

  factory Defect.fromMap(Map<String, dynamic> map) {
    return Defect(
      id: map['id'] as int?,
      inspectionId: map['inspectionId'] as int,
      vehicleId: map['vehicleId'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      severity: map['severity'] as String,
      repaired: (map['repaired'] as int) == 1,
      reportedDate: DateTime.parse(map['reportedDate'] as String),
    );
  }
}