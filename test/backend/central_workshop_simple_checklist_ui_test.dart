import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Workshop checklist keeps the quick inspection workflow', () {
    final source = File(
      'lib/features/workshop/screens/central_workshop_inspection_details_screen.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'Pass'"));
    expect(source, contains("label: 'Advisory'"));
    expect(source, contains("label: 'Fail'"));
    expect(source, contains("label: 'N/A'"));
    expect(source, contains("label: const Text('Photo')"));
    expect(source, contains("label: const Text('Create repair')"));
    expect(source, contains("labelText: 'Inspection notes'"));
    expect(source, contains('onStatusChanged: _quickSaveChecklistStatus'));
    expect(
      source,
      isNot(contains("title: Text(item == null ? 'Add checklist item'")),
    );
  });
}
