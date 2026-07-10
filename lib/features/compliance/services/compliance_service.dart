import '../models/vehicle_compliance.dart';

class ComplianceService {
  const ComplianceService();

  ComplianceStatus getStatus(DateTime? expiryDate) {
    if (expiryDate == null) {
      return ComplianceStatus.missing;
    }

    final now = DateTime.now();

    if (expiryDate.isBefore(now)) {
      return ComplianceStatus.overdue;
    }

    if (expiryDate.difference(now).inDays <= 30) {
      return ComplianceStatus.dueSoon;
    }

    return ComplianceStatus.valid;
  }

  int daysRemaining(DateTime? expiryDate) {
    if (expiryDate == null) {
      return 0;
    }

    return expiryDate.difference(DateTime.now()).inDays;
  }

  String statusText(ComplianceStatus status) {
    switch (status) {
      case ComplianceStatus.valid:
        return "Valid";

      case ComplianceStatus.dueSoon:
        return "Due Soon";

      case ComplianceStatus.overdue:
        return "Overdue";

      case ComplianceStatus.missing:
        return "Missing";
    }
  }
}