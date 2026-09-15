class CentralDriverAssignment {
  const CentralDriverAssignment({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.assignedFrom,
    required this.isActive,
    required this.vehicleRegistration,
    required this.vehicleFleetNumber,
    this.assignedTo,
    this.vehicleMake,
    this.vehicleModel,
  });

  final String id;
  final String driverId;
  final String vehicleId;
  final DateTime assignedFrom;
  final DateTime? assignedTo;
  final bool isActive;
  final String vehicleRegistration;
  final String vehicleFleetNumber;
  final String? vehicleMake;
  final String? vehicleModel;

  bool get isCurrent => isActive && assignedTo == null;

  String get vehicleLabel {
    final fleetNumber = vehicleFleetNumber.trim();
    if (fleetNumber.isEmpty) {
      return vehicleRegistration;
    }
    return '$vehicleRegistration · $fleetNumber';
  }

  String get vehicleDescription {
    final parts = <String>[
      if ((vehicleMake ?? '').trim().isNotEmpty) vehicleMake!.trim(),
      if ((vehicleModel ?? '').trim().isNotEmpty) vehicleModel!.trim(),
    ];
    return parts.isEmpty ? 'Vehicle details unavailable' : parts.join(' ');
  }
}
