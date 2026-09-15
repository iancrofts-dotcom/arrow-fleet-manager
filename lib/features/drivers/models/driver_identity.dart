enum DriverIdentityKind { local, central }

class DriverIdentity {
  DriverIdentity.local(int id)
    : kind = DriverIdentityKind.local,
      _localId = _validateLocalId(id),
      _centralId = null;

  DriverIdentity.central(String id)
    : kind = DriverIdentityKind.central,
      _localId = null,
      _centralId = _validateCentralId(id);

  final DriverIdentityKind kind;
  final int? _localId;
  final String? _centralId;

  int? get localIdOrNull => _localId;
  String? get centralIdOrNull => _centralId;

  int requireLocalId(String operation) {
    final id = _localId;
    if (id == null) {
      throw UnsupportedError('$operation requires a local driver ID.');
    }
    return id;
  }

  static int _validateLocalId(int id) {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Must be positive.');
    }
    return id;
  }

  static String _validateCentralId(String id) {
    final normalized = id.toLowerCase();
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ).hasMatch(normalized)) {
      throw const FormatException('Invalid central driver UUID.');
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) =>
      other is DriverIdentity &&
      other.kind == kind &&
      other._localId == _localId &&
      other._centralId == _centralId;

  @override
  int get hashCode => Object.hash(kind, _localId, _centralId);
}
