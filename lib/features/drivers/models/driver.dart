class Driver {
  const Driver({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.licenceNumber,
    this.licenceExpiry,
    this.phone,
    this.email,
    this.username,
    this.isActive = true,
  });

  final int? id;

  final String firstName;
  final String lastName;

  final String licenceNumber;
  final DateTime? licenceExpiry;

  final String? phone;
  final String? email;

  /// Username used to log into the mobile app.
  final String? username;

  final bool isActive;

  /// Driver's full display name.
  String get fullName => '$firstName $lastName';

  Driver copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? licenceNumber,
    DateTime? licenceExpiry,
    String? phone,
    String? email,
    String? username,
    bool? isActive,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      licenceNumber: licenceNumber ?? this.licenceNumber,
      licenceExpiry: licenceExpiry ?? this.licenceExpiry,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      username: username ?? this.username,
      isActive: isActive ?? this.isActive,
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
      'username': username,
      'active': isActive ? 1 : 0,
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
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      username: map['username'] as String?,
      isActive: (map['active'] ?? 1) == 1,
    );
  }

  @override
  String toString() {
    return 'Driver('
        'id: $id, '
        'firstName: $firstName, '
        'lastName: $lastName, '
        'licenceNumber: $licenceNumber, '
        'licenceExpiry: $licenceExpiry, '
        'phone: $phone, '
        'email: $email, '
        'username: $username, '
        'isActive: $isActive'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Driver &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.licenceNumber == licenceNumber &&
        other.licenceExpiry == licenceExpiry &&
        other.phone == phone &&
        other.email == email &&
        other.username == username &&
        other.isActive == isActive;
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
      username,
      isActive,
    );
  }
}