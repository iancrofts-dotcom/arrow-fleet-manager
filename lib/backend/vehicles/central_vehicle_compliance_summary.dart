import 'backend_vehicle.dart';

enum CentralComplianceState { valid, dueSoon, overdue, missing }

class CentralVehicleComplianceSummary {
  const CentralVehicleComplianceSummary({
    required this.motOverdue,
    required this.motDueSoon,
    required this.motMissing,
    required this.serviceOverdue,
    required this.serviceDueSoon,
    required this.serviceMissing,
  });

  final int motOverdue;
  final int motDueSoon;
  final int motMissing;
  final int serviceOverdue;
  final int serviceDueSoon;
  final int serviceMissing;

  int get urgentCount => motOverdue + serviceOverdue;

  factory CentralVehicleComplianceSummary.fromVehicles(
    Iterable<BackendVehicle> vehicles, {
    DateTime? now,
  }) {
    final reference = _dateOnly(now ?? DateTime.now());
    var motOverdue = 0;
    var motDueSoon = 0;
    var motMissing = 0;
    var serviceOverdue = 0;
    var serviceDueSoon = 0;
    var serviceMissing = 0;

    for (final vehicle in vehicles.where((vehicle) => vehicle.isActive)) {
      switch (centralComplianceState(vehicle.motExpiry, now: reference)) {
        case CentralComplianceState.overdue:
          motOverdue++;
        case CentralComplianceState.dueSoon:
          motDueSoon++;
        case CentralComplianceState.missing:
          motMissing++;
        case CentralComplianceState.valid:
          break;
      }
      switch (centralComplianceState(vehicle.serviceDue, now: reference)) {
        case CentralComplianceState.overdue:
          serviceOverdue++;
        case CentralComplianceState.dueSoon:
          serviceDueSoon++;
        case CentralComplianceState.missing:
          serviceMissing++;
        case CentralComplianceState.valid:
          break;
      }
    }

    return CentralVehicleComplianceSummary(
      motOverdue: motOverdue,
      motDueSoon: motDueSoon,
      motMissing: motMissing,
      serviceOverdue: serviceOverdue,
      serviceDueSoon: serviceDueSoon,
      serviceMissing: serviceMissing,
    );
  }
}

CentralComplianceState centralComplianceState(
  DateTime? dueDate, {
  DateTime? now,
}) {
  if (dueDate == null) return CentralComplianceState.missing;
  final today = _dateOnly(now ?? DateTime.now());
  final due = _dateOnly(dueDate);
  if (due.isBefore(today)) return CentralComplianceState.overdue;
  if (due.difference(today).inDays <= 30) return CentralComplianceState.dueSoon;
  return CentralComplianceState.valid;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
