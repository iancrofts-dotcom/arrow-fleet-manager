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

  String get fullName => '$firstName $lastName';

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
      licenceNumber: licenceNumber ?? this.licenceNumber,
      licenceExpiry: licenceExpiry ?? this.licenceExpiry,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'licence_number': licenceNumber,
      'licence_expiry': licenceExpiry?.millisecondsSinceEpoch,
      'phone': phone,
      'email': email,
      'active': active ? 1 : 0,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['id'] as int?,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      licenceNumber: map['licence_number'] as String,
      licenceExpiry: map['licence_expiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['licence_expiry'] as int,
            )
          : null,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      active: (map['active'] ?? 1) == 1,
    );
  }

  @override
  String toString() {
    return 'Driver(id: $id, name: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Driver &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.licenceNumber == licenceNumber &&
        other.licenceExpiry == licenceExpiry &&
        other.phone == phone &&
        other.email == email &&
        other.active == active;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      firstName,
      lastName,
      licenceNumber,
      licenceExpiry,
      phone,
      email,
      active,
    );
  }
}