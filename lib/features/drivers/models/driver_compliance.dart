class DriverCompliance {
  const DriverCompliance({
    required this.driverId,
    required this.licenceExpiry,
    required this.cpcExpiry,
    required this.medicalExpiry,
  });

  final int driverId;
  final DateTime licenceExpiry;
  final DateTime cpcExpiry;
  final DateTime medicalExpiry;

  bool get licenceExpired =>
      licenceExpiry.isBefore(DateTime.now());

  bool get cpcExpired =>
      cpcExpiry.isBefore(DateTime.now());

  bool get medicalExpired =>
      medicalExpiry.isBefore(DateTime.now());

  int get licenceDaysRemaining =>
      licenceExpiry.difference(DateTime.now()).inDays;

  int get cpcDaysRemaining =>
      cpcExpiry.difference(DateTime.now()).inDays;

  int get medicalDaysRemaining =>
      medicalExpiry.difference(DateTime.now()).inDays;

  bool get hasWarnings =>
      licenceDaysRemaining <= 30 ||
      cpcDaysRemaining <= 30 ||
      medicalDaysRemaining <= 30;

  DriverCompliance copyWith({
    int? driverId,
    DateTime? licenceExpiry,
    DateTime? cpcExpiry,
    DateTime? medicalExpiry,
  }) {
    return DriverCompliance(
      driverId: driverId ?? this.driverId,
      licenceExpiry: licenceExpiry ?? this.licenceExpiry,
      cpcExpiry: cpcExpiry ?? this.cpcExpiry,
      medicalExpiry:
          medicalExpiry ?? this.medicalExpiry,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'licenceExpiry':
          licenceExpiry.toIso8601String(),
      'cpcExpiry':
          cpcExpiry.toIso8601String(),
      'medicalExpiry':
          medicalExpiry.toIso8601String(),
    };
  }

  factory DriverCompliance.fromMap(
    Map<String, dynamic> map,
  ) {
    return DriverCompliance(
      driverId: map['driverId'] as int,
      licenceExpiry: DateTime.parse(
        map['licenceExpiry'] as String,
      ),
      cpcExpiry: DateTime.parse(
        map['cpcExpiry'] as String,
      ),
      medicalExpiry: DateTime.parse(
        map['medicalExpiry'] as String,
      ),
    );
  }
}