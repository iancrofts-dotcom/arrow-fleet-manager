enum ComplianceStatus {
  valid,
  dueSoon,
  overdue,
  missing,
}

class VehicleCompliance {
  final DateTime? motExpiry;
  final DateTime? insuranceExpiry;
  final DateTime? roadTaxExpiry;
  final DateTime? serviceDueDate;

  const VehicleCompliance({
    this.motExpiry,
    this.insuranceExpiry,
    this.roadTaxExpiry,
    this.serviceDueDate,
  });

  ComplianceStatus motStatus() =>
      _calculateStatus(motExpiry);

  ComplianceStatus insuranceStatus() =>
      _calculateStatus(insuranceExpiry);

  ComplianceStatus roadTaxStatus() =>
      _calculateStatus(roadTaxExpiry);

  ComplianceStatus serviceStatus() =>
      _calculateStatus(serviceDueDate);

  ComplianceStatus _calculateStatus(
    DateTime? date,
  ) {
    if (date == null) {
      return ComplianceStatus.missing;
    }

    final now = DateTime.now();

    if (date.isBefore(now)) {
      return ComplianceStatus.overdue;
    }

    if (date.difference(now).inDays <= 30) {
      return ComplianceStatus.dueSoon;
    }

    return ComplianceStatus.valid;
  }
}