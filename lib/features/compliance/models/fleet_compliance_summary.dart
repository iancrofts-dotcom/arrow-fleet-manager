import 'dart:collection';

/// The condition of a single required fleet-compliance check.
enum FleetComplianceStatus { valid, dueSoon, expired, notRecorded }

/// The persisted entity that owns a compliance check.
enum FleetComplianceSubjectType { vehicle, driver }

/// The required checks included in the fleet-wide compliance percentage.
enum FleetComplianceCheckType {
  mot,
  service,
  licence,
  cpc,
  medical,
  dbs,
  taxiLicence,
  taxiPlate,
}

/// A non-compliant or soon-to-be-non-compliant persisted check.
///
/// [subjectId] is the persisted Vehicle or Driver ID used for future routing;
/// presentation text is intentionally not used as an identifier.
class FleetComplianceAttentionItem {
  const FleetComplianceAttentionItem({
    required this.subjectType,
    required this.subjectId,
    required this.checkType,
    required this.status,
    required this.date,
    required this.subjectDisplay,
    this.secondaryDisplay,
  });

  final FleetComplianceSubjectType subjectType;
  final int subjectId;
  final FleetComplianceCheckType checkType;
  final FleetComplianceStatus status;
  final DateTime? date;
  final String subjectDisplay;
  final String? secondaryDisplay;
}

/// Immutable, Dashboard-compatible fleet compliance data for presentation.
///
/// [compliantChecks] counts valid and due-soon required checks. The status
/// counts partition [totalChecks], while vehicle and driver check counts
/// partition the same total.
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
  }) : attentionItems = UnmodifiableListView(attentionItems) {
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
}
