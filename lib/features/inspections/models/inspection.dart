class Inspection {
  final int? id;

  final String inspectionNumber;
  final DateTime inspectionDate;

  /// Linked Vehicle
  int? vehicleId;

  /// Temporary until every screen uses Vehicle ID
  String registration;

  /// Driver completing the walkaround
  String driver;

  /// Current odometer reading
  int mileage;

  /// Fuel level recorded by the driver
  String fuelLevel;

  /// Driver comments
  String comments;

  /// Overall inspection result
  String overallResult;

  /// Inspection status
  String status;

  Inspection({
    this.id,
    required this.inspectionNumber,
    required this.inspectionDate,
    this.vehicleId,
    this.registration = '',
    this.driver = '',
    this.mileage = 0,
    this.fuelLevel = 'Full',
    this.comments = '',
    this.overallResult = 'Pending',
    this.status = 'New',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionNumber': inspectionNumber,
      'inspectionDate': inspectionDate.toIso8601String(),
      'vehicleId': vehicleId,
      'registration': registration,
      'driver': driver,
      'mileage': mileage,
      'fuelLevel': fuelLevel,
      'comments': comments,
      'overallResult': overallResult,
      'status': status,
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
      mileage: map['mileage'] ?? 0,
      fuelLevel: map['fuelLevel'] ?? 'Full',
      comments: map['comments'] ?? '',
      overallResult: map['overallResult'] ?? 'Pending',
      status: map['status'] ?? 'New',
    );
  }

  Inspection copyWith({
    int? id,
    String? inspectionNumber,
    DateTime? inspectionDate,
    int? vehicleId,
    String? registration,
    String? driver,
    int? mileage,
    String? fuelLevel,
    String? comments,
    String? overallResult,
    String? status,
  }) {
    return Inspection(
      id: id ?? this.id,
      inspectionNumber:
          inspectionNumber ?? this.inspectionNumber,
      inspectionDate:
          inspectionDate ?? this.inspectionDate,
      vehicleId: vehicleId ?? this.vehicleId,
      registration:
          registration ?? this.registration,
      driver: driver ?? this.driver,
      mileage: mileage ?? this.mileage,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      comments: comments ?? this.comments,
      overallResult:
          overallResult ?? this.overallResult,
      status: status ?? this.status,
    );
  }
}