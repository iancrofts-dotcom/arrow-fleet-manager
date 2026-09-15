import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central native Workshop launches the original five-step wizard flow', () {
    final source = File(
      'lib/features/workshop/screens/inspection_wizard/central_inspection_wizard_screen.dart',
    ).readAsStringSync();

    for (final step in [
      'Vehicle',
      'Checklist',
      'Summary',
      'Repairs',
      'Sign-off',
    ]) {
      expect(source, contains("'$step'"));
    }
    expect(source, contains('Step2Checklist('));
    expect(source, contains('Step3Summary('));
    expect(source, contains('Step4Repairs('));
    expect(source, contains('Step5Signoff('));
    expect(source, contains('CentralInspectionWizardSaveService'));
  });

  test(
    'central wizard save happens at finish rather than each checklist tap',
    () {
      final wizard = File(
        'lib/features/workshop/screens/inspection_wizard/central_inspection_wizard_screen.dart',
      ).readAsStringSync();
      final checklist = File(
        'lib/features/workshop/screens/inspection_wizard/step2_checklist.dart',
      ).readAsStringSync();

      expect(wizard, contains('_saveService.saveInspection(wizardData)'));
      expect(checklist, contains('void _setStatus('));
      expect(checklist, isNot(contains('SupabaseWorkshopGateway')));
      expect(checklist, isNot(contains('saveInspectionItem(')));
    },
  );

  test('central identity is separate from local SQLite integer identity', () {
    final data = File(
      'lib/features/workshop/models/inspection_wizard_data.dart',
    ).readAsStringSync();
    expect(data, contains('String? centralVehicleId;'));
    expect(data, contains('String? centralTemplateId;'));
    expect(data, contains('int? vehicleId;'));
    expect(data, contains('int? templateId;'));
  });
}
