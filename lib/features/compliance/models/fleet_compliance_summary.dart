import 'dart:collection';

enum FleetComplianceStatus { valid, dueSoon, expired, notRecorded }

enum FleetComplianceSubjectType { vehicle, driver }

enum FleetComplianceCheckType {
  mot,
  psvMot,
  service,
  psvGarageCheck,
  taxiSafetyCheck,
  licence,
  cpc,
  medical,
  dbs,
  taxiLicence,
  taxiPlate,
}

class FleetComplianceAttentionItem {
  const FleetComplianceAttentionItem({
    required this.subjectType,
    required this.subjectId,
    required this.checkType,
    required this.status,
    required this.date,
    required this.subjectDisplay,
    this.secondaryDisplay,
    this.centralSubjectId,
  });

  final FleetComplianceSubjectType subjectType;
  final int subjectId;
  final FleetComplianceCheckType checkType;
  final FleetComplianceStatus status;
  final DateTime? date;
  final String subjectDisplay;
  final String? secondaryDisplay;
  final String? centralSubjectId;
}

class FleetComplianceSummary {
  FleetComplianceSummary({
    required this.compliancePercentage,
    required this.totalChecks,
    required this.compliantChecks,
    required this.validCount,
    required this.dueSoonCount,
    required this.expiredCount,
    required this.notRecordedCount,
    required this.vehicleCheckCount,
    required this.driverCheckCount,
    required List<FleetComplianceAttentionItem> attentionItems,
    List<FleetComplianceAttentionItem>? allItems,
  }) : attentionItems = UnmodifiableListView(attentionItems),
       allItems = UnmodifiableListView(allItems ?? attentionItems) {
    assert(
      validCount + dueSoonCount + expiredCount + notRecordedCount ==
          totalChecks,
    );
    assert(vehicleCheckCount + driverCheckCount == totalChecks);
  }

  final int compliancePercentage;
  final int totalChecks;
  final int compliantChecks;
  final int validCount;
  final int dueSoonCount;
  final int expiredCount;
  final int notRecordedCount;
  final int vehicleCheckCount;
  final int driverCheckCount;
  final UnmodifiableListView<FleetComplianceAttentionItem> attentionItems;

  /// Full fleet compliance register, including valid records.
  final UnmodifiableListView<FleetComplianceAttentionItem> allItems;
}
