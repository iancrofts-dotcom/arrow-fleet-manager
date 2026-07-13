class Driver {
  final int? id;
  final String firstName;
  final String lastName;
  final String licenceNumber;
  final DateTime? licenceExpiry;
  final String phone;
  final String email;
  final bool active;

  const Driver({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.licenceNumber,
    this.licenceExpiry,
    required this.phone,
    required this.email,
    this.active = true,
  });

  String get fullName =>
      '$firstName $lastName';

  Driver copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? licenceNumber,
    DateTime? licenceExpiry,
    String? phone,
    String? email,
    bool? active,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      licenceNumber:
          licenceNumber ?? this.licenceNumber,
      licenceExpiry:
          licenceExpiry ?? this.licenceExpiry,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      active: active ?? this.active,
    );
  }
}