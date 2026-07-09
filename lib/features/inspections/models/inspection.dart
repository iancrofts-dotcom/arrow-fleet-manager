class Inspection {
  final int? id;

  final String inspectionNumber;
  final DateTime inspectionDate;

  /// New for Inspection v2
  final int? vehicleId;

  String registration;
  String driver;
  String inspector;
  int mileage;
  String comments;

  Inspection({
    this.id,
    required this.inspectionNumber,
    required this.inspectionDate,
    this.vehicleId,
    this.registration = '',
    this.driver = '',
    this.inspector = '',
    this.mileage = 0,
    this.comments = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionNumber': inspectionNumber,
      'inspectionDate': inspectionDate.toIso8601String(),
      'vehicleId': vehicleId,
      'registration': registration,
      'driver': driver,
      'inspector': inspector,
      'mileage': mileage,
      'comments': comments,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    return Inspection(
      id: map['id'] as int?,
      inspectionNumber: map['inspectionNumber'] ?? '',
      inspectionDate: DateTime.parse(map['inspectionDate']),
      vehicleId: map['vehicleId'] as int?,
      registration: map['registration'] ?? '',
      driver: map['driver'] ?? '',
      inspector: map['inspector'] ?? '',
      mileage: map['mileage'] ?? 0,
      comments: map['comments'] ?? '',
    );
  }

  Inspection copyWith({
    int? id,
    String? inspectionNumber,
    DateTime? inspectionDate,
    int? vehicleId,
    String? registration,
    String? driver,
    String? inspector,
    int? mileage,
    String? comments,
  }) {
    return Inspection(
      id: id ?? this.id,
      inspectionNumber: inspectionNumber ?? this.inspectionNumber,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      vehicleId: vehicleId ?? this.vehicleId,
      registration: registration ?? this.registration,
      driver: driver ?? this.driver,
      inspector: inspector ?? this.inspector,
      mileage: mileage ?? this.mileage,
      comments: comments ?? this.comments,
    );
  }
}