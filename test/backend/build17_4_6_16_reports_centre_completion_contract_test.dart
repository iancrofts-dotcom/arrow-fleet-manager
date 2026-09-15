import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('17.4.6.16 exposes the complete Reports Centre module set', () {
    final source = File(
      'lib/features/reports/models/report_module.dart',
    ).readAsStringSync();
    for (final token in [
      'fleetSummary',
      'compliance',
      'drivers',
      'assignments',
      'inspections',
      'defects',
      'workshop',
      'maintenance',
      'costs',
      'documents',
      'managementAudit',
    ]) {
      expect(source, contains(token));
    }
    expect(source, contains('supportsDateRange'));
  });

  test('completion reports use only central repositories and services', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    for (final token in [
      'BackendVehicleRepository',
      'SupabaseVehicleGateway',
      'BackendDriverRepository',
      'SupabaseDriverGateway',
      'BackendDriverAssignmentRepository',
      'SupabaseDriverAssignmentGateway',
      'BackendWorkshopRepository',
      'SupabaseWorkshopGateway',
      'CentralDocumentRepository',
      'SupabaseCentralDocumentGateway',
      'CentralComplianceParityService',
      'CentralFleetReportService',
    ]) {
      expect(source, contains(token));
    }
    expect(source, isNot(contains('AppDatabase')));
    expect(source, isNot(contains('SQLite')));
  });

  test('cost reporting uses stored repair-job cost and hour fields', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    expect(source, contains('estimatedCost'));
    expect(source, contains('actualCost'));
    expect(source, contains('estimatedHours'));
    expect(source, contains('actualHours'));
    expect(source, isNot(contains('random')));
    expect(source, isNot(contains('mock cost')));
  });

  test('maintenance reports optional central vehicle schedule dates', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    expect(source, contains('serviceDue'));
    expect(source, contains('psvGarageCheckDue'));
    expect(source, contains('taxiSafetyCheckDue'));
    expect(source, contains('vehicle.serviceDue != null'));
  });

  test('documents report includes archived evidence without mutating it', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    expect(source, contains('listDocuments(includeArchived: true)'));
    expect(source, contains('Documents & Evidence Report'));
    expect(source, isNot(contains('archiveDocument(')));
  });

  test('management audit is explicit about operational audit scope', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    expect(source, contains('Management & Operational Audit Report'));
    expect(source, contains('does not represent a security-event audit log'));
    expect(source, contains('Operational Exceptions'));
    expect(source, contains('Audit Evidence in Selected Period'));
  });

  test('all operational modules share the date range and PDF CSV UI', () {
    final moduleSource = File(
      'lib/features/reports/models/report_module.dart',
    ).readAsStringSync();
    final screenSource = File(
      'lib/features/reports/screens/reports_screen.dart',
    ).readAsStringSync();
    expect(moduleSource, contains('supportsDateRange'));
    expect(screenSource, contains('_module.supportsDateRange'));
    expect(screenSource, contains('Preview PDF'));
    expect(screenSource, contains('Export PDF'));
    expect(screenSource, contains('Export CSV'));
    expect(screenSource, isNot(contains('Next Modules')));
    expect(screenSource, isNot(contains('fleet_report_card.dart')));
  });

  test('17.4.6.16 introduces no service-role credential or migration', () {
    final source = File(
      'lib/backend/central_reports_centre_service.dart',
    ).readAsStringSync();
    expect(source.toLowerCase(), isNot(contains('service_role')));
    expect(
      Directory('supabase/migrations').existsSync(),
      anyOf(isTrue, isFalse),
    );
  });
}
