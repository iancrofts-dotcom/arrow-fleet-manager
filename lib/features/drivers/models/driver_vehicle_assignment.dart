class DriverVehicleAssignment {
  final int? id;
  final int driverId;
  final int vehicleId;
  final DateTime assignedFrom;
  final DateTime? assignedTo;
  final bool active;

  const DriverVehicleAssignment({
    this.id,
    required this.driverId,
    required this.vehicleId,
    required this.assignedFrom,
    this.assignedTo,
    this.active = true,
  });

  DriverVehicleAssignment copyWith({
    int? id,
    int? driverId,
    int? vehicleId,
    DateTime? assignedFrom,
    DateTime? assignedTo,
    bool? active,
  }) {
    return DriverVehicleAssignment(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      assignedFrom: assignedFrom ?? this.assignedFrom,
      assignedTo: assignedTo ?? this.assignedTo,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'assigned_from': assignedFrom.millisecondsSinceEpoch,
      'assigned_to': assignedTo?.millisecondsSinceEpoch,
      'active': active ? 1 : 0,
    };
  }

  factory DriverVehicleAssignment.fromMap(
    Map<String, dynamic> map,
  ) {
    return DriverVehicleAssignment(
      id: map['id'] as int?,
      driverId: map['driver_id'] as int,
      vehicleId: map['vehicle_id'] as int,
      assignedFrom: DateTime.fromMillisecondsSinceEpoch(
        map['assigned_from'] as int,
      ),
      assignedTo: map['assigned_to'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              map['assigned_to'] as int,
            ),
      active: (map['active'] as int) == 1,
    );
  }

  bool get isCurrent =>
      active && assignedTo == null;
}