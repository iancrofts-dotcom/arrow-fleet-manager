class BackendVehicle {
  const BackendVehicle({
    required this.id,
    required this.registration,
    required this.fleetNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.legacyId,
    this.make,
    this.model,
    this.manufactureYear,
    this.vin,
    this.motExpiry,
    this.serviceDue,
    this.taxiPlateNumber,
    this.taxiLicensingAuthority,
    this.taxiPlateIssueDate,
    this.taxiPlateExpiry,
  });

  final String id;
  final int? legacyId;
  final String registration;
  final String fleetNumber;
  final String? make;
  final String? model;
  final int? manufactureYear;
  final String? vin;
  final DateTime? motExpiry;
  final DateTime? serviceDue;
  final String? taxiPlateNumber;
  final String? taxiLicensingAuthority;
  final DateTime? taxiPlateIssueDate;
  final DateTime? taxiPlateExpiry;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BackendVehicle.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (!uuid.hasMatch(id)) {
      throw const FormatException('Invalid vehicle id.');
    }
    return BackendVehicle(
      id: id,
      legacyId: json['legacy_id'] as int?,
      registration: _requiredString(json, 'registration'),
      fleetNumber: _requiredString(json, 'fleet_number'),
      make: json['make'] as String?,
      model: json['model'] as String?,
      manufactureYear: json['manufacture_year'] as int?,
      vin: json['vin'] as String?,
      motExpiry: _optionalDate(json, 'mot_expiry'),
      serviceDue: _optionalDate(json, 'service_due'),
      taxiPlateNumber: json['taxi_plate_number'] as String?,
      taxiLicensingAuthority: json['taxi_licensing_authority'] as String?,
      taxiPlateIssueDate: _optionalDate(json, 'taxi_plate_issue_date'),
      taxiPlateExpiry: _optionalDate(json, 'taxi_plate_expiry'),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(_requiredString(json, 'created_at')),
      updatedAt: DateTime.parse(_requiredString(json, 'updated_at')),
    );
  }
}

class BackendVehicleWrite {
  const BackendVehicleWrite({
    required this.registration,
    required this.fleetNumber,
    this.legacyId,
    this.make,
    this.model,
    this.manufactureYear,
    this.vin,
    this.motExpiry,
    this.serviceDue,
    this.taxiPlateNumber,
    this.taxiLicensingAuthority,
    this.taxiPlateIssueDate,
    this.taxiPlateExpiry,
    this.isActive = true,
  });

  final int? legacyId;
  final String registration;
  final String fleetNumber;
  final String? make;
  final String? model;
  final int? manufactureYear;
  final String? vin;
  final DateTime? motExpiry;
  final DateTime? serviceDue;
  final String? taxiPlateNumber;
  final String? taxiLicensingAuthority;
  final DateTime? taxiPlateIssueDate;
  final DateTime? taxiPlateExpiry;
  final bool isActive;

  Map<String, dynamic> toInsertJson() => {
    'legacy_id': legacyId,
    ...toUpdateJson(),
  };

  Map<String, dynamic> toUpdateJson() => {
    'registration': registration,
    'fleet_number': fleetNumber,
    'make': make,
    'model': model,
    'manufacture_year': manufactureYear,
    'vin': vin,
    'mot_expiry': _serializeDate(motExpiry),
    'service_due': _serializeDate(serviceDue),
    'taxi_plate_number': taxiPlateNumber,
    'taxi_licensing_authority': taxiLicensingAuthority,
    'taxi_plate_issue_date': _serializeDate(taxiPlateIssueDate),
    'taxi_plate_expiry': _serializeDate(taxiPlateExpiry),
    'is_active': isActive,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value == null ? null : DateTime.parse(value as String);
}

String? _serializeDate(DateTime? value) => value == null
    ? null
    : '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
