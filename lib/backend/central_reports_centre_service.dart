import '../features/compliance/models/fleet_compliance_summary.dart';
import '../features/reports/models/report_document.dart';
import '../features/reports/models/report_module.dart';
import 'central_compliance_parity_service.dart';
import 'central_fleet_report_service.dart';
import 'documents/central_document_repository.dart';
import 'documents/supabase_central_document_gateway.dart';
import 'drivers/backend_driver_assignment_repository.dart';
import 'drivers/backend_driver_repository.dart';
import 'drivers/supabase_driver_assignment_gateway.dart';
import 'drivers/supabase_driver_gateway.dart';
import 'vehicles/backend_vehicle_repository.dart';
import 'vehicles/supabase_vehicle_gateway.dart';
import 'workshop/backend_workshop_repository.dart';
import 'workshop/supabase_workshop_gateway.dart';

class CentralReportsCentreService {
  CentralReportsCentreService({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Future<ReportDocument> generate(ReportModuleQuery query) async {
    return switch (query.module) {
      ReportModule.fleetSummary => _fleetSummary(),
      ReportModule.compliance => _compliance(),
      ReportModule.drivers => _drivers(),
      ReportModule.assignments => _assignments(query),
      ReportModule.inspections => _inspections(query),
      ReportModule.defects => _defects(query),
      ReportModule.workshop => _workshop(query),
      ReportModule.maintenance => _maintenance(query),
      ReportModule.costs => _costs(query),
      ReportModule.documents => _documents(query),
      ReportModule.managementAudit => _managementAudit(query),
    };
  }

  Future<ReportDocument> _fleetSummary() async {
    final report = await CentralFleetReportService(now: _now).generateReport();
    return ReportDocument(
      id: 'fleet-summary',
      title: 'Fleet Summary',
      subtitle: 'Current fleet compliance and operational snapshot.',
      generatedAt: report.generatedAt,
      sections: [
        ReportSection(
          title: 'Fleet',
          rows: [
            ReportRow(label: 'Vehicles', value: '${report.vehicles}'),
            ReportRow(
              label: 'Active Vehicles',
              value: '${report.activeVehicles}',
            ),
            ReportRow(
              label: 'Inactive Vehicles',
              value: '${report.inactiveVehicles}',
            ),
            ReportRow(label: 'Fleet Health', value: '${report.fleetHealth}%'),
          ],
        ),
        ReportSection(
          title: 'Compliance & Maintenance',
          rows: [
            ReportRow(label: 'MOT Due', value: '${report.motDue}'),
            ReportRow(label: 'Service Due', value: '${report.serviceDue}'),
            ReportRow(label: 'Overdue', value: '${report.overdue}'),
          ],
        ),
        ReportSection(
          title: 'Operations',
          rows: [
            ReportRow(label: 'Inspections', value: '${report.inspections}'),
            ReportRow(label: 'Defects', value: '${report.defects}'),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _compliance() async {
    final summary = await CentralComplianceParityService(
      now: _now,
    ).loadSummary();
    return ReportDocument(
      id: 'compliance',
      title: 'Compliance Report',
      subtitle:
          'Fleet and driver compliance status from the live central register.',
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Summary',
          rows: [
            ReportRow(
              label: 'Compliance Rate',
              value: '${summary.compliancePercentage}%',
            ),
            ReportRow(label: 'Total Checks', value: '${summary.totalChecks}'),
            ReportRow(label: 'Valid', value: '${summary.validCount}'),
            ReportRow(label: 'Due Soon', value: '${summary.dueSoonCount}'),
            ReportRow(label: 'Expired', value: '${summary.expiredCount}'),
            ReportRow(
              label: 'Not Recorded',
              value: '${summary.notRecordedCount}',
            ),
            ReportRow(
              label: 'Vehicle Checks',
              value: '${summary.vehicleCheckCount}',
            ),
            ReportRow(
              label: 'Driver Checks',
              value: '${summary.driverCheckCount}',
            ),
          ],
        ),
        ReportSection(
          title: 'Compliance Register',
          rows: [
            for (final item in summary.allItems)
              ReportRow(
                label: '${item.subjectDisplay} · ${_checkType(item.checkType)}',
                value:
                    '${_status(item.status)}${item.date == null ? '' : ' · ${_date(item.date!)}'}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _drivers() async {
    final drivers = await BackendDriverRepository(
      SupabaseDriverGateway(),
    ).listDrivers();
    drivers.sort((a, b) {
      final byLast = a.lastName.compareTo(b.lastName);
      return byLast != 0 ? byLast : a.firstName.compareTo(b.firstName);
    });
    final active = drivers.where((driver) => driver.isActive).length;
    final now = _dateOnly(_now());
    final expired = drivers.where((driver) {
      final expiry = driver.licenceExpiry;
      return expiry != null && _dateOnly(expiry).isBefore(now);
    }).length;

    return ReportDocument(
      id: 'drivers',
      title: 'Driver Report',
      subtitle: 'Driver register and licence status.',
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Summary',
          rows: [
            ReportRow(label: 'Drivers', value: '${drivers.length}'),
            ReportRow(label: 'Active Drivers', value: '$active'),
            ReportRow(
              label: 'Inactive Drivers',
              value: '${drivers.length - active}',
            ),
            ReportRow(label: 'Expired Licences', value: '$expired'),
          ],
        ),
        ReportSection(
          title: 'Driver Register',
          rows: [
            for (final driver in drivers)
              ReportRow(
                label: '${driver.firstName} ${driver.lastName}'.trim(),
                value:
                    '${driver.isActive ? 'Active' : 'Inactive'} · Licence ${driver.licenceNumber}${driver.licenceExpiry == null ? ' · Expiry not recorded' : ' · Expires ${_date(driver.licenceExpiry!)}'}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _assignments(ReportModuleQuery query) async {
    final assignments = await BackendDriverAssignmentRepository(
      SupabaseDriverAssignmentGateway(),
    ).listAssignments();
    final drivers = await BackendDriverRepository(
      SupabaseDriverGateway(),
    ).listDrivers();
    final vehicles = await BackendVehicleRepository(
      SupabaseVehicleGateway(),
    ).listVehicles();
    final driverNames = {
      for (final driver in drivers)
        driver.id: '${driver.firstName} ${driver.lastName}'.trim(),
    };
    final vehicleNames = {
      for (final vehicle in vehicles) vehicle.id: vehicle.registration,
    };
    final filtered =
        assignments.where((item) => _inRange(item.assignedFrom, query)).toList()
          ..sort((a, b) => b.assignedFrom.compareTo(a.assignedFrom));
    final active = filtered.where((item) => item.isActive).length;

    return ReportDocument(
      id: 'assignments',
      title: 'Driver Assignment Report',
      subtitle: _rangeSubtitle('Driver-to-vehicle assignment history', query),
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Summary',
          rows: [
            ReportRow(label: 'Assignments', value: '${filtered.length}'),
            ReportRow(label: 'Active Assignments', value: '$active'),
            ReportRow(
              label: 'Ended Assignments',
              value: '${filtered.length - active}',
            ),
          ],
        ),
        ReportSection(
          title: 'Assignment Register',
          rows: [
            for (final assignment in filtered)
              ReportRow(
                label:
                    '${driverNames[assignment.driverId] ?? 'Unknown driver'} · ${vehicleNames[assignment.vehicleId] ?? 'Unknown vehicle'}',
                value:
                    '${_date(assignment.assignedFrom)} to ${assignment.assignedTo == null ? 'Current' : _date(assignment.assignedTo!)} · ${assignment.isActive ? 'Active' : 'Ended'}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _inspections(ReportModuleQuery query) async {
    final inspections = await BackendWorkshopRepository(
      SupabaseWorkshopGateway(),
    ).listInspections();
    final filtered =
        inspections.where((item) => _inRange(item.dateStarted, query)).toList()
          ..sort((a, b) => b.dateStarted.compareTo(a.dateStarted));
    final completed = filtered.where((item) => item.isCompleted).length;
    final failed = filtered
        .where((item) => item.overallResult.toLowerCase() == 'fail')
        .length;
    final critical = filtered.fold<int>(
      0,
      (sum, item) => sum + item.criticalFailures,
    );

    return ReportDocument(
      id: 'inspections',
      title: 'Inspection Report',
      subtitle: _rangeSubtitle('Workshop and operational inspections', query),
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Summary',
          rows: [
            ReportRow(label: 'Inspections', value: '${filtered.length}'),
            ReportRow(label: 'Completed', value: '$completed'),
            ReportRow(label: 'Open', value: '${filtered.length - completed}'),
            ReportRow(label: 'Failed', value: '$failed'),
            ReportRow(label: 'Critical Failures', value: '$critical'),
          ],
        ),
        ReportSection(
          title: 'Inspection Register',
          rows: [
            for (final inspection in filtered)
              ReportRow(
                label:
                    '${inspection.inspectionNumber} · ${inspection.registration}',
                value:
                    '${_date(inspection.dateStarted)} · ${_humanize(inspection.status)} · ${inspection.overallResult.isEmpty ? 'Result not recorded' : inspection.overallResult}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _defects(ReportModuleQuery query) async {
    final jobs = await BackendWorkshopRepository(
      SupabaseWorkshopGateway(),
    ).listRepairJobs();
    final filtered =
        jobs.where((job) => _inRange(job.createdAt, query)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final outstanding = filtered.where((job) => job.isOutstanding).length;
    final completed = filtered.where((job) => job.status == 'completed').length;
    final critical = filtered
        .where((job) => job.priority.toLowerCase() == 'critical')
        .length;
    final parts = filtered.where((job) => job.partsRequired).length;

    return ReportDocument(
      id: 'defects',
      title: 'Defects & Repair Report',
      subtitle: _rangeSubtitle('Recorded defects and repair jobs', query),
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Summary',
          rows: [
            ReportRow(
              label: 'Defects / Repair Jobs',
              value: '${filtered.length}',
            ),
            ReportRow(label: 'Outstanding', value: '$outstanding'),
            ReportRow(label: 'Completed', value: '$completed'),
            ReportRow(label: 'Critical Priority', value: '$critical'),
            ReportRow(label: 'Parts Required', value: '$parts'),
          ],
        ),
        ReportSection(
          title: 'Defect Register',
          rows: [
            for (final job in filtered)
              ReportRow(
                label:
                    '${job.jobNumber} · ${job.vehicleRegistration} · ${job.title}',
                value:
                    '${_date(job.createdAt)} · ${_humanize(job.priority)} · ${_humanize(job.status)}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _workshop(ReportModuleQuery query) async {
    final repository = BackendWorkshopRepository(SupabaseWorkshopGateway());
    final inspections =
        (await repository.listInspections())
            .where((item) => _inRange(item.dateStarted, query))
            .toList()
          ..sort((a, b) => b.dateStarted.compareTo(a.dateStarted));
    final jobs =
        (await repository.listRepairJobs())
            .where((item) => _inRange(item.createdAt, query))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final openInspections = inspections.where((item) => item.isOpen).length;
    final completedInspections = inspections
        .where((item) => item.isCompleted)
        .length;
    final outstandingRepairs = jobs.where((item) => item.isOutstanding).length;
    final awaitingParts = jobs
        .where((item) => item.status.toLowerCase() == 'awaitingparts')
        .length;
    final criticalFailures = inspections.fold<int>(
      0,
      (sum, item) => sum + item.criticalFailures,
    );

    return ReportDocument(
      id: 'workshop',
      title: 'Workshop Operations Report',
      subtitle: _rangeSubtitle('Workshop workload and repair activity', query),
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Workshop Summary',
          rows: [
            ReportRow(label: 'Inspections', value: '${inspections.length}'),
            ReportRow(label: 'Open Inspections', value: '$openInspections'),
            ReportRow(
              label: 'Completed Inspections',
              value: '$completedInspections',
            ),
            ReportRow(label: 'Repair Jobs', value: '${jobs.length}'),
            ReportRow(
              label: 'Outstanding Repairs',
              value: '$outstandingRepairs',
            ),
            ReportRow(label: 'Awaiting Parts', value: '$awaitingParts'),
            ReportRow(label: 'Critical Failures', value: '$criticalFailures'),
          ],
        ),
        ReportSection(
          title: 'Inspection Activity',
          rows: [
            for (final inspection in inspections)
              ReportRow(
                label:
                    '${inspection.inspectionNumber} · ${inspection.registration}',
                value:
                    '${_date(inspection.dateStarted)} · ${_humanize(inspection.status)} · ${inspection.technicianName.isEmpty ? 'Technician not recorded' : inspection.technicianName}',
              ),
          ],
        ),
        ReportSection(
          title: 'Repair Activity',
          rows: [
            for (final job in jobs)
              ReportRow(
                label:
                    '${job.jobNumber} · ${job.vehicleRegistration} · ${job.title}',
                value:
                    '${_date(job.createdAt)} · ${_humanize(job.status)} · ${_humanize(job.priority)}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _maintenance(ReportModuleQuery query) async {
    final vehicles = await BackendVehicleRepository(
      SupabaseVehicleGateway(),
    ).listVehicles();
    final schedules = <_MaintenanceSchedule>[];
    for (final vehicle in vehicles) {
      if (vehicle.serviceDue != null) {
        schedules.add(
          _MaintenanceSchedule(
            registration: vehicle.registration,
            type: 'Service',
            due: vehicle.serviceDue!,
            activeVehicle: vehicle.isActive,
          ),
        );
      }
      if (vehicle.psvGarageCheckEnabled && vehicle.psvGarageCheckDue != null) {
        schedules.add(
          _MaintenanceSchedule(
            registration: vehicle.registration,
            type: 'PSV Garage Check',
            due: vehicle.psvGarageCheckDue!,
            activeVehicle: vehicle.isActive,
          ),
        );
      }
      if (vehicle.taxiSafetyCheckEnabled &&
          vehicle.taxiSafetyCheckDue != null) {
        schedules.add(
          _MaintenanceSchedule(
            registration: vehicle.registration,
            type: 'Taxi Safety Check',
            due: vehicle.taxiSafetyCheckDue!,
            activeVehicle: vehicle.isActive,
          ),
        );
      }
    }
    final filtered =
        schedules.where((item) => _inRange(item.due, query)).toList()
          ..sort((a, b) => a.due.compareTo(b.due));
    final today = _dateOnly(_now());
    final dueSoonLimit = today.add(const Duration(days: 30));
    final overdue = filtered
        .where((item) => _dateOnly(item.due).isBefore(today))
        .length;
    final dueSoon = filtered.where((item) {
      final due = _dateOnly(item.due);
      return !due.isBefore(today) && !due.isAfter(dueSoonLimit);
    }).length;

    return ReportDocument(
      id: 'maintenance',
      title: 'Maintenance Schedule Report',
      subtitle: _rangeSubtitle(
        'Recorded service and scheduled vehicle safety-check due dates',
        query,
      ),
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Summary',
          rows: [
            ReportRow(label: 'Scheduled Items', value: '${filtered.length}'),
            ReportRow(label: 'Overdue', value: '$overdue'),
            ReportRow(label: 'Due Within 30 Days', value: '$dueSoon'),
          ],
        ),
        ReportSection(
          title: 'Maintenance Schedule',
          rows: [
            for (final item in filtered)
              ReportRow(
                label: '${item.registration} · ${item.type}',
                value:
                    '${_date(item.due)} · ${_dueStatus(item.due, today)}${item.activeVehicle ? '' : ' · Vehicle inactive'}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _costs(ReportModuleQuery query) async {
    final jobs =
        (await BackendWorkshopRepository(
              SupabaseWorkshopGateway(),
            ).listRepairJobs())
            .where((item) => _inRange(item.createdAt, query))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final estimatedCost = jobs.fold<double>(
      0,
      (sum, item) => sum + item.estimatedCost,
    );
    final actualCost = jobs.fold<double>(
      0,
      (sum, item) => sum + item.actualCost,
    );
    final estimatedHours = jobs.fold<double>(
      0,
      (sum, item) => sum + item.estimatedHours,
    );
    final actualHours = jobs.fold<double>(
      0,
      (sum, item) => sum + item.actualHours,
    );
    final actualByVehicle = <String, double>{};
    for (final job in jobs) {
      actualByVehicle.update(
        job.vehicleRegistration,
        (value) => value + job.actualCost,
        ifAbsent: () => job.actualCost,
      );
    }
    final vehicleCosts = actualByVehicle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ReportDocument(
      id: 'costs',
      title: 'Workshop Cost Report',
      subtitle: _rangeSubtitle(
        'Stored repair-job estimates, actual costs and labour hours',
        query,
      ),
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Cost Summary',
          rows: [
            ReportRow(label: 'Repair Jobs', value: '${jobs.length}'),
            ReportRow(label: 'Estimated Cost', value: _currency(estimatedCost)),
            ReportRow(label: 'Actual Cost', value: _currency(actualCost)),
            ReportRow(
              label: 'Cost Variance',
              value: _currency(actualCost - estimatedCost),
            ),
            ReportRow(
              label: 'Estimated Labour Hours',
              value: estimatedHours.toStringAsFixed(1),
            ),
            ReportRow(
              label: 'Actual Labour Hours',
              value: actualHours.toStringAsFixed(1),
            ),
          ],
        ),
        ReportSection(
          title: 'Actual Cost by Vehicle',
          rows: [
            for (final item in vehicleCosts)
              ReportRow(label: item.key, value: _currency(item.value)),
          ],
        ),
        ReportSection(
          title: 'Repair Job Cost Register',
          rows: [
            for (final job in jobs)
              ReportRow(
                label:
                    '${job.jobNumber} · ${job.vehicleRegistration} · ${job.title}',
                value:
                    '${_date(job.createdAt)} · Est ${_currency(job.estimatedCost)} · Actual ${_currency(job.actualCost)} · ${_humanize(job.status)}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _documents(ReportModuleQuery query) async {
    final documents =
        (await CentralDocumentRepository(
              const SupabaseCentralDocumentGateway(),
            ).listDocuments(includeArchived: true))
            .where((item) => _inRange(item.createdAt, query))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final today = _dateOnly(_now());
    final dueSoonLimit = today.add(const Duration(days: 30));
    final archived = documents.where((item) => item.isArchived).length;
    final expired = documents.where((item) {
      final expiry = item.expiresOn;
      return expiry != null && _dateOnly(expiry).isBefore(today);
    }).length;
    final expiringSoon = documents.where((item) {
      final expiry = item.expiresOn;
      if (expiry == null) return false;
      final day = _dateOnly(expiry);
      return !day.isBefore(today) && !day.isAfter(dueSoonLimit);
    }).length;

    return ReportDocument(
      id: 'documents-evidence',
      title: 'Documents & Evidence Report',
      subtitle: _rangeSubtitle(
        'Central document and evidence register, including archived records',
        query,
      ),
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Summary',
          rows: [
            ReportRow(label: 'Documents', value: '${documents.length}'),
            ReportRow(
              label: 'Active Documents',
              value: '${documents.length - archived}',
            ),
            ReportRow(label: 'Archived Documents', value: '$archived'),
            ReportRow(label: 'Expired', value: '$expired'),
            ReportRow(label: 'Expiring Within 30 Days', value: '$expiringSoon'),
          ],
        ),
        ReportSection(
          title: 'Document Register',
          rows: [
            for (final document in documents)
              ReportRow(
                label:
                    '${document.title.trim().isEmpty ? document.fileName : document.title} · ${_humanize(document.category)}',
                value:
                    '${_humanize(document.entityType)} · ${_date(document.createdAt)} · ${document.expiresOn == null ? 'No expiry recorded' : 'Expires ${_date(document.expiresOn!)}'} · ${_fileSize(document.sizeBytes)}${document.isArchived ? ' · Archived' : ''}',
              ),
          ],
        ),
      ],
    );
  }

  Future<ReportDocument> _managementAudit(ReportModuleQuery query) async {
    final fleet = await CentralFleetReportService(now: _now).generateReport();
    final compliance = await CentralComplianceParityService(
      now: _now,
    ).loadSummary();
    final drivers = await BackendDriverRepository(
      SupabaseDriverGateway(),
    ).listDrivers();
    final assignments =
        (await BackendDriverAssignmentRepository(
              SupabaseDriverAssignmentGateway(),
            ).listAssignments())
            .where((item) => _inRange(item.assignedFrom, query))
            .toList();
    final workshop = BackendWorkshopRepository(SupabaseWorkshopGateway());
    final inspections = (await workshop.listInspections())
        .where((item) => _inRange(item.dateStarted, query))
        .toList();
    final jobs = (await workshop.listRepairJobs())
        .where((item) => _inRange(item.createdAt, query))
        .toList();
    final documents =
        (await CentralDocumentRepository(
              const SupabaseCentralDocumentGateway(),
            ).listDocuments(includeArchived: true))
            .where((item) => _inRange(item.createdAt, query))
            .toList();
    final activeDrivers = drivers.where((item) => item.isActive).length;
    final openRepairs = jobs.where((item) => item.isOutstanding).length;
    final criticalRepairs = jobs
        .where((item) => item.priority.toLowerCase() == 'critical')
        .length;
    final failedInspections = inspections
        .where((item) => item.overallResult.toLowerCase() == 'fail')
        .length;
    final archivedDocuments = documents.where((item) => item.isArchived).length;
    final actualRepairCost = jobs.fold<double>(
      0,
      (sum, item) => sum + item.actualCost,
    );

    return ReportDocument(
      id: 'management-audit',
      title: 'Management & Operational Audit Report',
      subtitle:
          '${_rangeSubtitle('Executive snapshot and operational audit evidence', query)} This report does not represent a security-event audit log.',
      generatedAt: _now(),
      sections: [
        ReportSection(
          title: 'Executive Snapshot',
          rows: [
            ReportRow(label: 'Fleet Health', value: '${fleet.fleetHealth}%'),
            ReportRow(
              label: 'Compliance Rate',
              value: '${compliance.compliancePercentage}%',
            ),
            ReportRow(
              label: 'Active Vehicles',
              value: '${fleet.activeVehicles}',
            ),
            ReportRow(label: 'Active Drivers', value: '$activeDrivers'),
            ReportRow(label: 'MOT Due', value: '${fleet.motDue}'),
            ReportRow(label: 'Service Due', value: '${fleet.serviceDue}'),
            ReportRow(label: 'Overdue', value: '${fleet.overdue}'),
          ],
        ),
        ReportSection(
          title: 'Operational Exceptions',
          rows: [
            ReportRow(
              label: 'Expired Compliance Checks',
              value: '${compliance.expiredCount}',
            ),
            ReportRow(
              label: 'Compliance Due Soon',
              value: '${compliance.dueSoonCount}',
            ),
            ReportRow(label: 'Open Repairs', value: '$openRepairs'),
            ReportRow(label: 'Critical Repair Jobs', value: '$criticalRepairs'),
            ReportRow(label: 'Failed Inspections', value: '$failedInspections'),
          ],
        ),
        ReportSection(
          title: 'Audit Evidence in Selected Period',
          rows: [
            ReportRow(label: 'Assignments', value: '${assignments.length}'),
            ReportRow(label: 'Inspections', value: '${inspections.length}'),
            ReportRow(label: 'Repair Jobs', value: '${jobs.length}'),
            ReportRow(
              label: 'Documents / Evidence',
              value: '${documents.length}',
            ),
            ReportRow(label: 'Archived Documents', value: '$archivedDocuments'),
            ReportRow(
              label: 'Recorded Actual Repair Cost',
              value: _currency(actualRepairCost),
            ),
          ],
        ),
        const ReportSection(
          title: 'Audit Scope',
          rows: [
            ReportRow(
              label: 'Operational Evidence',
              value:
                  'Fleet, compliance, assignments, inspections, repairs and documents included.',
            ),
            ReportRow(
              label: 'Security Event Audit Log',
              value:
                  'Not included because the current central backend does not expose a security-event audit source to Reports Centre.',
            ),
          ],
        ),
      ],
    );
  }

  bool _inRange(DateTime value, ReportModuleQuery query) {
    final day = _dateOnly(value);
    final from = query.from == null ? null : _dateOnly(query.from!);
    final to = query.to == null ? null : _dateOnly(query.to!);
    if (from != null && day.isBefore(from)) return false;
    if (to != null && day.isAfter(to)) return false;
    return true;
  }

  String _rangeSubtitle(String prefix, ReportModuleQuery query) {
    if (!query.hasDateRange) return '$prefix · all available records.';
    final from = query.from == null ? 'earliest' : _date(query.from!);
    final to = query.to == null ? 'latest' : _date(query.to!);
    return '$prefix · $from to $to.';
  }
}

class _MaintenanceSchedule {
  const _MaintenanceSchedule({
    required this.registration,
    required this.type,
    required this.due,
    required this.activeVehicle,
  });

  final String registration;
  final String type;
  final DateTime due;
  final bool activeVehicle;
}

String _checkType(FleetComplianceCheckType type) => switch (type) {
  FleetComplianceCheckType.mot => 'MOT',
  FleetComplianceCheckType.psvMot => 'PSV MOT',
  FleetComplianceCheckType.service => 'Service',
  FleetComplianceCheckType.psvGarageCheck => 'PSV Garage Check',
  FleetComplianceCheckType.taxiSafetyCheck => 'Taxi Safety Check',
  FleetComplianceCheckType.licence => 'Driving Licence',
  FleetComplianceCheckType.cpc => 'CPC',
  FleetComplianceCheckType.medical => 'Medical',
  FleetComplianceCheckType.dbs => 'DBS',
  FleetComplianceCheckType.taxiLicence => 'Taxi Licence',
  FleetComplianceCheckType.taxiPlate => 'Taxi Plate',
};

String _status(FleetComplianceStatus status) => switch (status) {
  FleetComplianceStatus.valid => 'Valid',
  FleetComplianceStatus.dueSoon => 'Due Soon',
  FleetComplianceStatus.expired => 'Expired',
  FleetComplianceStatus.notRecorded => 'Not Recorded',
};

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dueStatus(DateTime due, DateTime today) {
  final day = _dateOnly(due);
  if (day.isBefore(today)) return 'Overdue';
  if (!day.isAfter(today.add(const Duration(days: 30)))) {
    return 'Due within 30 days';
  }
  return 'Scheduled';
}

String _currency(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign£${value.abs().toStringAsFixed(2)}';
}

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _humanize(String value) {
  final text = value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ')
      .trim();
  if (text.isEmpty) return 'Not recorded';
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
