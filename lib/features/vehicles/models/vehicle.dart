class Vehicle {
  int? id;

  String registration;
  String fleetNumber;
  String make;
  String model;
  int year;
  String vin;

  DateTime? motExpiry;
  DateTime? serviceDue;

  bool active;

  Vehicle({
    this.id,
    required this.registration,
    required this.fleetNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    this.motExpiry,
    this.serviceDue,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
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
      active: (map['active'] ?? 1) == 1,
    );
  }
}