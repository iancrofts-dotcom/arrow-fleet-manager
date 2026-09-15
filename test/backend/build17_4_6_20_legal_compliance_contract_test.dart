import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legal compliance migration is tenant scoped and versioned', () {
    final s = File(
      'supabase/migrations/20260915073000_legal_gdpr_commercial_compliance.sql',
    ).readAsStringSync();
    expect(s, contains('fleet_legal_acceptances'));
    expect(s, contains('fleet_current_organisation_id()'));
    expect(s, contains('fleet_required_legal_acceptances'));
    expect(s, contains('fleet_create_data_request'));
    expect(s, contains('fleet_create_offboarding_request'));
  });
  test('company management exposes Legal and Privacy Centre', () {
    final s = File(
      'lib/features/auth/screens/central/central_organisation_management_screen.dart',
    ).readAsStringSync();
    expect(s, contains('Legal & Privacy Centre'));
    expect(s, contains('CentralLegalCentreScreen'));
  });
  test('legal service records acceptance and controlled requests', () {
    final s = File(
      'lib/backend/legal/central_legal_service.dart',
    ).readAsStringSync();
    expect(s, contains('fleet_accept_legal_document'));
    expect(s, contains('fleet_create_data_request'));
    expect(s, contains('fleet_create_offboarding_request'));
  });
}
