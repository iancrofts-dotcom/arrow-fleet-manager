enum VehicleIdentityKind { local, central }

class VehicleIdentity {
  VehicleIdentity._({required this.kind, this.localId, this.centralId});

  factory VehicleIdentity.local(int id) {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Local vehicle ID must be positive.');
    }
    return VehicleIdentity._(kind: VehicleIdentityKind.local, localId: id);
  }

  factory VehicleIdentity.central(String id) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    if (!uuid.hasMatch(id)) {
      throw FormatException('Invalid central vehicle UUID.');
    }
    return VehicleIdentity._(
      kind: VehicleIdentityKind.central,
      centralId: id.toLowerCase(),
    );
  }

  final VehicleIdentityKind kind;
  final int? localId;
  final String? centralId;

  int? get localIdOrNull => localId;
  String? get centralIdOrNull => centralId;

  int requireLocalId(String operation) {
    final id = localId;
    if (id == null) {
      throw UnsupportedError(
        '$operation requires a local SQLite vehicle identity.',
      );
    }
    return id;
  }

  @override
  bool operator ==(Object other) =>
      other is VehicleIdentity &&
      other.kind == kind &&
      other.localId == localId &&
      other.centralId == centralId;

  @override
  int get hashCode => Object.hash(kind, localId, centralId);

  @override
  String toString() => switch (kind) {
    VehicleIdentityKind.local => 'VehicleIdentity.local($localId)',
    VehicleIdentityKind.central => 'VehicleIdentity.central($centralId)',
  };
}
