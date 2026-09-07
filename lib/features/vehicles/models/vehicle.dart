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
      active: (map['active'] ?? 1) == 1,
    );
  }
}
