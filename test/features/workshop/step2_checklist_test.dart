import 'dart:async';

import 'package:arrow_fleet_manager/features/workshop/models/inspection_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_template_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_template_section.dart';
import 'package:arrow_fleet_manager/features/workshop/models/inspection_wizard_data.dart';
import 'package:arrow_fleet_manager/features/workshop/repositories/inspection_template_repository.dart';
import 'package:arrow_fleet_manager/features/workshop/screens/inspection_wizard/step2_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step2Checklist custom template loading', () {
    testWidgets('loads active custom-template checklist items', (tester) async {
      await _pumpChecklist(
        tester,
        data: _data(1),
        repository: _FakeTemplateRepository(
          items: (_) async => [_item(1, title: 'Brake pads')],
          sections: (_) async => [_section(1, title: 'Brakes')],
        ),
      );

      expect(find.text('Brake pads'), findsOneWidget);
      expect(find.text('Brakes'), findsOneWidget);
    });

    testWidgets('shows an error when custom-template items fail to load', (
      tester,
    ) async {
      await _pumpChecklist(
        tester,
        data: _data(1),
        repository: _FakeTemplateRepository(
          items: (_) => Future.error(StateError('items unavailable')),
          sections: (_) async => [_section(1)],
        ),
      );

      expect(find.text('Unable to load checklist.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('shows an error when custom-template sections fail to load', (
      tester,
    ) async {
      await _pumpChecklist(
        tester,
        data: _data(1),
        repository: _FakeTemplateRepository(
          items: (_) async => [_item(1)],
          sections: (_) => Future.error(StateError('sections unavailable')),
        ),
      );

      expect(find.text('Unable to load checklist.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retry recovers after a failed custom-template load', (
      tester,
    ) async {
      var itemAttempts = 0;
      await _pumpChecklist(
        tester,
        data: _data(1),
        repository: _FakeTemplateRepository(
          items: (_) {
            itemAttempts++;
            if (itemAttempts == 1) {
              return Future.error(StateError('items unavailable'));
            }
            return Future.value([_item(1, title: 'Recovered item')]);
          },
          sections: (_) async => [_section(1)],
        ),
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered item'), findsOneWidget);
      expect(find.text('Unable to load checklist.'), findsNothing);
      expect(itemAttempts, 2);
    });

    testWidgets('ignores a stale custom-template completion after a new load', (
      tester,
    ) async {
      final firstItems = Completer<List<InspectionTemplateItem>>();
      final firstSections = Completer<List<InspectionTemplateSection>>();
      final secondItems = Completer<List<InspectionTemplateItem>>();
      final secondSections = Completer<List<InspectionTemplateSection>>();
      final data = _data(1);
      late StateSetter rebuild;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Scaffold(
                body: Step2Checklist(
                  data: data,
                  onNext: () {},
                  onPrevious: () {},
                  templateRepository: _FakeTemplateRepository(
                    items: (templateId) => templateId == 1
                        ? firstItems.future
                        : secondItems.future,
                    sections: (templateId) => templateId == 1
                        ? firstSections.future
                        : secondSections.future,
                  ),
                ),
              );
            },
          ),
        ),
      );

      data.templateId = 2;
      rebuild(() {});
      await tester.pump();

      secondItems.complete([_item(2, title: 'Current item')]);
      secondSections.complete([_section(2)]);
      await tester.pumpAndSettle();

      firstItems.complete([_item(1, title: 'Stale item')]);
      firstSections.complete([_section(1)]);
      await tester.pumpAndSettle();

      expect(find.text('Current item'), findsOneWidget);
      expect(find.text('Stale item'), findsNothing);
    });

    testWidgets('default checklist does not load custom-template data', (
      tester,
    ) async {
      await _pumpChecklist(
        tester,
        data: InspectionWizardData(),
        repository: _FakeTemplateRepository(
          items: (_) => Future.error(StateError('should not be called')),
          sections: (_) => Future.error(StateError('should not be called')),
        ),
      );

      expect(find.text('Registration Plate'), findsOneWidget);
    });
  });
}

Future<void> _pumpChecklist(
  WidgetTester tester, {
  required InspectionWizardData data,
  required InspectionTemplateRepository repository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Step2Checklist(
          data: data,
          onNext: () {},
          onPrevious: () {},
          templateRepository: repository,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

InspectionWizardData _data(int templateId) => InspectionWizardData()
  ..templateId = templateId;

InspectionTemplateItem _item(int templateId, {String title = 'Item'}) =>
    InspectionTemplateItem(
      id: templateId,
      templateId: templateId,
      sectionId: templateId,
      category: InspectionCategory.brakes,
      title: title,
      displayOrder: 0,
    );

InspectionTemplateSection _section(int templateId, {String title = 'Section'}) =>
    InspectionTemplateSection(
      id: templateId,
      templateId: templateId,
      title: title,
      displayOrder: 0,
    );

class _FakeTemplateRepository extends InspectionTemplateRepository {
  _FakeTemplateRepository({required this.items, required this.sections});

  final Future<List<InspectionTemplateItem>> Function(int) items;
  final Future<List<InspectionTemplateSection>> Function(int) sections;

  @override
  Future<List<InspectionTemplateItem>> getTemplateItems(int templateId) =>
      items(templateId);

  @override
  Future<List<InspectionTemplateSection>> getTemplateSections(int templateId) =>
      sections(templateId);
}
