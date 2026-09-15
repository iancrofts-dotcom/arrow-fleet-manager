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
    this.motType = 'standard',
    this.psvGarageCheckEnabled = false,
    this.psvGarageCheckIntervalWeeks = 6,
    this.psvGarageCheckLastDate,
    this.psvGarageCheckDue,
    this.taxiSafetyCheckEnabled = false,
    this.taxiSafetyCheckIntervalWeeks = 6,
    this.taxiSafetyCheckLastDate,
    this.taxiSafetyCheckDue,
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
  final String motType;
  final bool psvGarageCheckEnabled;
  final int psvGarageCheckIntervalWeeks;
  final DateTime? psvGarageCheckLastDate;
  final DateTime? psvGarageCheckDue;
  final bool taxiSafetyCheckEnabled;
  final int taxiSafetyCheckIntervalWeeks;
  final DateTime? taxiSafetyCheckLastDate;
  final DateTime? taxiSafetyCheckDue;
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
      fleetNumber: _optionalStringOrEmpty(json, 'fleet_number'),
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
      motType: json['mot_type'] as String? ?? 'standard',
      psvGarageCheckEnabled: json['psv_garage_check_enabled'] as bool? ?? false,
      psvGarageCheckIntervalWeeks:
          (json['psv_garage_check_interval_weeks'] as num?)?.toInt() ?? 6,
      psvGarageCheckLastDate: _optionalDate(json, 'psv_garage_check_last_date'),
      psvGarageCheckDue: _optionalDate(json, 'psv_garage_check_due'),
      taxiSafetyCheckEnabled:
          json['taxi_safety_check_enabled'] as bool? ?? false,
      taxiSafetyCheckIntervalWeeks:
          (json['taxi_safety_check_interval_weeks'] as num?)?.toInt() ?? 6,
      taxiSafetyCheckLastDate: _optionalDate(
        json,
        'taxi_safety_check_last_date',
      ),
      taxiSafetyCheckDue: _optionalDate(json, 'taxi_safety_check_due'),
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
    this.motType = 'standard',
    this.psvGarageCheckEnabled = false,
    this.psvGarageCheckIntervalWeeks = 6,
    this.psvGarageCheckLastDate,
    this.psvGarageCheckDue,
    this.taxiSafetyCheckEnabled = false,
    this.taxiSafetyCheckIntervalWeeks = 6,
    this.taxiSafetyCheckLastDate,
    this.taxiSafetyCheckDue,
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
  final String motType;
  final bool psvGarageCheckEnabled;
  final int psvGarageCheckIntervalWeeks;
  final DateTime? psvGarageCheckLastDate;
  final DateTime? psvGarageCheckDue;
  final bool taxiSafetyCheckEnabled;
  final int taxiSafetyCheckIntervalWeeks;
  final DateTime? taxiSafetyCheckLastDate;
  final DateTime? taxiSafetyCheckDue;
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
    'mot_type': motType,
    'psv_garage_check_enabled': psvGarageCheckEnabled,
    'psv_garage_check_interval_weeks': psvGarageCheckIntervalWeeks,
    'psv_garage_check_last_date': _serializeDate(psvGarageCheckLastDate),
    'psv_garage_check_due': _serializeDate(psvGarageCheckDue),
    'taxi_safety_check_enabled': taxiSafetyCheckEnabled,
    'taxi_safety_check_interval_weeks': taxiSafetyCheckIntervalWeeks,
    'taxi_safety_check_last_date': _serializeDate(taxiSafetyCheckLastDate),
    'taxi_safety_check_due': _serializeDate(taxiSafetyCheckDue),
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

String _optionalStringOrEmpty(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return '';
  if (value is! String) {
    throw FormatException('Invalid $key.');
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
