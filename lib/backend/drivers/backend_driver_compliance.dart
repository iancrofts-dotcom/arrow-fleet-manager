class BackendDriverCompliance {
  const BackendDriverCompliance({
    required this.driverId,
    this.licenceExpiry,
    this.cpcExpiry,
    this.medicalExpiry,
    this.dbsExpiry,
    this.taxiLicenceNumber,
    this.taxiLicenceExpiry,
    required this.updatedAt,
  });

  final String driverId;
  final DateTime? licenceExpiry;
  final DateTime? cpcExpiry;
  final DateTime? medicalExpiry;
  final DateTime? dbsExpiry;
  final String? taxiLicenceNumber;
  final DateTime? taxiLicenceExpiry;
  final DateTime updatedAt;

  factory BackendDriverCompliance.fromJson(Map<String, dynamic> json) =>
      BackendDriverCompliance(
        driverId: json['driver_id'] as String,
        licenceExpiry: _date(json['licence_expiry']),
        cpcExpiry: _date(json['cpc_expiry']),
        medicalExpiry: _date(json['medical_expiry']),
        dbsExpiry: _date(json['dbs_expiry']),
        taxiLicenceNumber: json['taxi_licence_number'] as String?,
        taxiLicenceExpiry: _date(json['taxi_licence_expiry']),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
