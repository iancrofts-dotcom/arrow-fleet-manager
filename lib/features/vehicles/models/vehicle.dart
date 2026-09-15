import 'vehicle_identity.dart';

class Vehicle {
  /// SQLite identity retained for backward compatibility. Central vehicles
  /// always have a null [id] and carry their UUID in [identity].
  final int? id;
  final VehicleIdentity? identity;

  String registration;
  String fleetNumber;
  String make;
  String model;
  int year;
  String vin;

  DateTime? motExpiry;
  DateTime? serviceDue;
  String? taxiPlateNumber;
  String? taxiLicensingAuthority;
  DateTime? taxiPlateIssueDate;
  DateTime? taxiPlateExpiry;
  String motType;
  bool psvGarageCheckEnabled;
  int psvGarageCheckIntervalWeeks;
  DateTime? psvGarageCheckLastDate;
  DateTime? psvGarageCheckDue;
  bool taxiSafetyCheckEnabled;
  int taxiSafetyCheckIntervalWeeks;
  DateTime? taxiSafetyCheckLastDate;
  DateTime? taxiSafetyCheckDue;

  bool active;

  Vehicle({
    int? id,
    VehicleIdentity? identity,
    required this.registration,
    required this.fleetNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
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
    this.active = true,
  }) : id = id,
       identity = _resolveIdentity(id, identity);

  static VehicleIdentity? _resolveIdentity(int? id, VehicleIdentity? identity) {
    if (identity?.centralIdOrNull != null && id != null) {
      throw ArgumentError(
        'A central vehicle cannot have a local SQLite vehicle ID.',
      );
    }
    if (identity?.localIdOrNull case final identityId?) {
      if (id != null && id != identityId) {
        throw ArgumentError('Local vehicle identity does not match id.');
      }
      return identity;
    }
    return identity ?? (id == null ? null : VehicleIdentity.local(id));
  }

  Map<String, dynamic> toMap() {
    if (identity?.centralIdOrNull != null) {
      throw UnsupportedError(
        'A central vehicle cannot be serialized for SQLite persistence.',
      );
    }
    return {
      'id': id,
      'registration': registration,
      'fleetNumber': fleetNumber,
      'make': make,
      'model': model,
      'year': year,
      'vin': vin,
      'motExpiry': motExpiry?.toIso8601String(),
      'serviceDue': serviceDue?.toIso8601String(),
      'taxiPlateNumber': taxiPlateNumber,
      'taxiLicensingAuthority': taxiLicensingAuthority,
      'taxiPlateIssueDate': taxiPlateIssueDate?.toIso8601String(),
      'taxiPlateExpiry': taxiPlateExpiry?.toIso8601String(),
      'active': active ? 1 : 0,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      registration: map['registration'] ?? '',
      fleetNumber: map['fleetNumber'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      vin: map['vin'] ?? '',
      motExpiry: map['motExpiry'] != null
          ? DateTime.parse(map['motExpiry'])
          : null,
      serviceDue: map['serviceDue'] != null
          ? DateTime.parse(map['serviceDue'])
          : null,
      taxiPlateNumber: map['taxiPlateNumber'] as String?,
      taxiLicensingAuthority: map['taxiLicensingAuthority'] as String?,
      taxiPlateIssueDate: map['taxiPlateIssueDate'] == null
          ? null
          : DateTime.parse(map['taxiPlateIssueDate']),
      taxiPlateExpiry: map['taxiPlateExpiry'] == null
          ? null
          : DateTime.parse(map['taxiPlateExpiry']),
      motType: map['motType'] as String? ?? 'standard',
      psvGarageCheckEnabled: (map['psvGarageCheckEnabled'] ?? 0) == 1,
      psvGarageCheckIntervalWeeks:
          (map['psvGarageCheckIntervalWeeks'] as num?)?.toInt() ?? 6,
      psvGarageCheckLastDate: map['psvGarageCheckLastDate'] == null
          ? null
          : DateTime.parse(map['psvGarageCheckLastDate']),
      psvGarageCheckDue: map['psvGarageCheckDue'] == null
          ? null
          : DateTime.parse(map['psvGarageCheckDue']),
      taxiSafetyCheckEnabled: (map['taxiSafetyCheckEnabled'] ?? 0) == 1,
      taxiSafetyCheckIntervalWeeks:
          (map['taxiSafetyCheckIntervalWeeks'] as num?)?.toInt() ?? 6,
      taxiSafetyCheckLastDate: map['taxiSafetyCheckLastDate'] == null
          ? null
          : DateTime.parse(map['taxiSafetyCheckLastDate']),
      taxiSafetyCheckDue: map['taxiSafetyCheckDue'] == null
          ? null
          : DateTime.parse(map['taxiSafetyCheckDue']),
      active: (map['active'] ?? 1) == 1,
    );
  }
}
