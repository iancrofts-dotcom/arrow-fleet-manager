enum ReportModule {
  fleetSummary,
  compliance,
  drivers,
  assignments,
  inspections,
  defects,
  workshop,
  maintenance,
  costs,
  documents,
  managementAudit,
}

extension ReportModuleLabel on ReportModule {
  String get label => switch (this) {
    ReportModule.fleetSummary => 'Fleet Summary',
    ReportModule.compliance => 'Compliance',
    ReportModule.drivers => 'Drivers',
    ReportModule.assignments => 'Assignments',
    ReportModule.inspections => 'Inspections',
    ReportModule.defects => 'Defects',
    ReportModule.workshop => 'Workshop',
    ReportModule.maintenance => 'Maintenance',
    ReportModule.costs => 'Costs',
    ReportModule.documents => 'Documents & Evidence',
    ReportModule.managementAudit => 'Management & Audit',
  };

  String get id => switch (this) {
    ReportModule.fleetSummary => 'fleet-summary',
    ReportModule.compliance => 'compliance',
    ReportModule.drivers => 'drivers',
    ReportModule.assignments => 'assignments',
    ReportModule.inspections => 'inspections',
    ReportModule.defects => 'defects',
    ReportModule.workshop => 'workshop',
    ReportModule.maintenance => 'maintenance',
    ReportModule.costs => 'costs',
    ReportModule.documents => 'documents-evidence',
    ReportModule.managementAudit => 'management-audit',
  };

  bool get supportsDateRange => switch (this) {
    ReportModule.assignments ||
    ReportModule.inspections ||
    ReportModule.defects ||
    ReportModule.workshop ||
    ReportModule.maintenance ||
    ReportModule.costs ||
    ReportModule.documents ||
    ReportModule.managementAudit => true,
    ReportModule.fleetSummary ||
    ReportModule.compliance ||
    ReportModule.drivers => false,
  };
}

class ReportModuleQuery {
  const ReportModuleQuery({required this.module, this.from, this.to});

  final ReportModule module;
  final DateTime? from;
  final DateTime? to;

  bool get hasDateRange => from != null || to != null;
}
