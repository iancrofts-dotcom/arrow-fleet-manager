class CentralVehicleAssignment {
  const CentralVehicleAssignment({
    required this.id,
    required this.driverId,
    required this.vehicleId,
    required this.assignedFrom,
    required this.isActive,
    required this.driverName,
    required this.driverLicenceNumber,
    this.assignedTo,
  });

  final String id;
  final String driverId;
  final String vehicleId;
  final DateTime assignedFrom;
  final DateTime? assignedTo;
  final bool isActive;
  final String driverName;
  final String driverLicenceNumber;

  bool get isCurrent => isActive && assignedTo == null;

  String get driverLabel {
    final licence = driverLicenceNumber.trim();
    if (licence.isEmpty) {
      return driverName;
    }
    return '$driverName · $licence';
  }
}
