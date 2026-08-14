class DriverCompliance {
  const DriverCompliance({
    required this.driverId,
    required this.licenceExpiry,
    required this.cpcExpiry,
    required this.medicalExpiry,
    this.dbsExpiry,
    required this.lastUpdated,
  });

  final int driverId;
  final DateTime licenceExpiry;
  final DateTime cpcExpiry;
  final DateTime medicalExpiry;
  final DateTime? dbsExpiry;

  /// Records when this compliance record was last created or updated.
  final DateTime lastUpdated;

  bool get licenceExpired =>
      licenceExpiry.isBefore(DateTime.now());

  bool get cpcExpired =>
      cpcExpiry.isBefore(DateTime.now());

  bool get medicalExpired =>
      medicalExpiry.isBefore(DateTime.now());
  bool get dbsExpired => dbsExpiry?.isBefore(DateTime.now()) ?? false;

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
    DateTime? dbsExpiry,
    DateTime? lastUpdated,
  }) {
    return DriverCompliance(
      driverId: driverId ?? this.driverId,
      licenceExpiry:
          licenceExpiry ?? this.licenceExpiry,
      cpcExpiry:
          cpcExpiry ?? this.cpcExpiry,
      medicalExpiry:
          medicalExpiry ?? this.medicalExpiry,
      dbsExpiry: dbsExpiry ?? this.dbsExpiry,
      lastUpdated:
          lastUpdated ?? this.lastUpdated,
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
      'dbsExpiry': dbsExpiry?.toIso8601String(),
      'lastUpdated':
          lastUpdated.toIso8601String(),
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
      dbsExpiry: map['dbsExpiry'] == null
          ? null
          : DateTime.parse(map['dbsExpiry'] as String),
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(
              map['lastUpdated'] as String,
            )
          : DateTime.now(),
    );
  }
}
