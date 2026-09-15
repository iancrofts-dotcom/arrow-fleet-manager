class BackendDriver {
  const BackendDriver({
    required this.id,
    this.legacyId,
    required this.firstName,
    required this.lastName,
    required this.licenceNumber,
    this.licenceExpiry,
    this.phone,
    this.email,
    this.username,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final int? legacyId;
  final String firstName;
  final String lastName;
  final String licenceNumber;
  final DateTime? licenceExpiry;
  final String? phone;
  final String? email;
  final String? username;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BackendDriver.fromJson(Map<String, dynamic> json) => BackendDriver(
    id: _uuid(json, 'id'),
    legacyId: json['legacy_id'] as int?,
    firstName: _string(json, 'first_name'),
    lastName: _string(json, 'last_name'),
    licenceNumber: _string(json, 'licence_number'),
    licenceExpiry: _date(json['licence_expiry']),
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    username: json['username'] as String?,
    isActive: json['is_active'] as bool,
    createdAt: DateTime.parse(_string(json, 'created_at')),
    updatedAt: DateTime.parse(_string(json, 'updated_at')),
  );
}

class BackendDriverWrite {
  const BackendDriverWrite({
    this.legacyId,
    required this.firstName,
    required this.lastName,
    required this.licenceNumber,
    this.licenceExpiry,
    this.phone,
    this.email,
    this.username,
    this.isActive = true,
  });
  final int? legacyId;
  final String firstName;
  final String lastName;
  final String licenceNumber;
  final DateTime? licenceExpiry;
  final String? phone;
  final String? email;
  final String? username;
  final bool isActive;
  Map<String, dynamic> toInsertJson() => {
    'legacy_id': legacyId,
    ...toUpdateJson(),
  };
  Map<String, dynamic> toUpdateJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'licence_number': licenceNumber,
    'licence_expiry': _dateText(licenceExpiry),
    'phone': phone,
    'email': email,
    'username': username,
    'is_active': isActive,
  };
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

String _uuid(Map<String, dynamic> json, String key) {
  final value = _string(json, key).toLowerCase();
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(value)) {
    throw FormatException('Invalid $key.');
  }
  return value;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
String? _dateText(DateTime? value) => value == null
    ? null
    : '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
