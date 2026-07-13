import '../models/driver.dart';

class DriverEntity {
  final int? id;
  final String firstName;
  final String lastName;
  final String licenceNumber;
  final DateTime? licenceExpiry;
  final String phone;
  final String email;
  final bool active;

  const DriverEntity({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.licenceNumber,
    this.licenceExpiry,
    required this.phone,
    required this.email,
    required this.active,
  });

  factory DriverEntity.fromDriver(
    Driver driver,
  ) {
    return DriverEntity(
      id: driver.id,
      firstName: driver.firstName,
      lastName: driver.lastName,
      licenceNumber: driver.licenceNumber,
      licenceExpiry: driver.licenceExpiry,
      phone: driver.phone,
      email: driver.email,
      active: driver.active,
    );
  }

  Driver toDriver() {
    return Driver(
      id: id,
      firstName: firstName,
      lastName: lastName,
      licenceNumber: licenceNumber,
      licenceExpiry: licenceExpiry,
      phone: phone,
      email: email,
      active: active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'licence_number': licenceNumber,
      'licence_expiry':
          licenceExpiry?.millisecondsSinceEpoch,
      'phone': phone,
      'email': email,
      'active': active ? 1 : 0,
    };
  }

  factory DriverEntity.fromMap(
    Map<String, dynamic> map,
  ) {
    return DriverEntity(
      id: map['id'] as int?,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      licenceNumber:
          map['licence_number'] as String,
      licenceExpiry:
          map['licence_expiry'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  map['licence_expiry'] as int,
                ),
      phone: map['phone'] as String,
      email: map['email'] as String,
      active: (map['active'] as int) == 1,
    );
  }
}