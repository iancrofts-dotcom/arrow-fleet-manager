import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repair details exposes one Job Card action and does not require source inspection to open',
    () {
      final source = File(
        'lib/features/workshop/screens/central_workshop_repair_job_details_screen.dart',
      ).readAsStringSync();

      expect(RegExp("Text\\('Open Job Card'\\)").allMatches(source).length, 1);
      expect(
        source,
        isNot(contains('if (inspection == null || _working) return;')),
      );
      expect(source, contains('inspection: _inspection'));
    },
  );

  test('job card viewer accepts a nullable source inspection', () {
    final source = File(
      'lib/features/workshop/screens/central_workshop_job_card_viewer_screen.dart',
    ).readAsStringSync();

    expect(source, contains('final BackendWorkshopInspection? inspection;'));
    expect(source, contains('if (inspection != null)'));
  });

  test('assigned Technician source inspection read policy is present', () {
    final sql = File(
      'supabase/migrations/20260911104000_workshop_assigned_technician_source_inspection_read.sql',
    ).readAsStringSync();

    expect(
      sql,
      contains('technicians read assigned repair source inspections'),
    );
    expect(sql, contains('repair.technician_profile_id = auth.uid()'));
    expect(sql, contains("repair.status <> 'cancelled'"));
  });
}
