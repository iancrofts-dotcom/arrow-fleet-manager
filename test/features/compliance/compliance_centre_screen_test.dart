import 'dart:async';

import 'package:arrow_fleet_manager/features/compliance/models/fleet_compliance_summary.dart';
import 'package:arrow_fleet_manager/features/compliance/screens/compliance_centre_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a loading state before the summary resolves', (
    tester,
  ) async {
    final completer = Completer<FleetComplianceSummary>();
    await _pump(tester, () => completer.future, settle: false);

    expect(find.text('Loading fleet compliance...'), findsOneWidget);

    completer.complete(_summary());
    await tester.pump();
  });

  testWidgets(
    'renders authoritative summary metrics and attention in service order',
    (tester) async {
      await _pump(tester, () async => _summary());

      expect(find.text('Compliance Centre'), findsOneWidget);
      expect(
        find.byKey(const Key('fleet-compliance-percentage')),
        findsOneWidget,
      );
      expect(find.text('67%'), findsOneWidget);
      expect(
        find.byKey(const Key('fleet-compliance-progress')),
        findsOneWidget,
      );
      expect(find.text('4 of 6 required checks compliant'), findsOneWidget);
      expect(find.byKey(const Key('compliance-status-Valid')), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      await _scrollTo(tester, find.text('Needs Attention'));
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('AB12 CDE'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('MOT • 12 Aug 2026'), findsOneWidget);
      expect(find.text('CPC • 21 Sep 2026'), findsOneWidget);
      expect(find.text('DBS • No date recorded'), findsOneWidget);
      await _scrollTo(tester, find.text('Vehicle Checks'));
      expect(find.text('Vehicle Checks'), findsOneWidget);
      expect(find.text('2 required checks'), findsOneWidget);
      expect(find.text('Driver Checks'), findsOneWidget);
      expect(find.text('4 required checks'), findsOneWidget);
      expect(find.text('Refresh'), findsNothing);
      expect(find.textContaining('Insurance'), findsNothing);
      expect(find.textContaining('Tax'), findsNothing);

      expect(
        tester.getTopLeft(find.text('AB12 CDE')).dy,
        lessThan(tester.getTopLeft(find.text('Jane Smith')).dy),
      );
    },
  );

  testWidgets('shows a positive empty-attention state', (tester) async {
    await _pump(tester, () async => _summary(attentionItems: []));
    await _scrollTo(
      tester,
      find.text('All required compliance checks are currently up to date.'),
    );

    expect(
      find.text('All required compliance checks are currently up to date.'),
      findsOneWidget,
    );
  });

  testWidgets('error retry starts another load', (tester) async {
    var loads = 0;
    await _pump(tester, () async {
      loads++;
      if (loads == 1) throw StateError('load failed');
      return _summary();
    });

    expect(find.text('Unable to load compliance'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(loads, 2);
    expect(find.text('Fleet Compliance'), findsOneWidget);
  });

  testWidgets(
    'opens attention subjects by persisted ID and reloads on return',
    (tester) async {
      var loads = 0;
      final openedItems = <FleetComplianceAttentionItem>[];
      await _pump(
        tester,
        () async {
          loads++;
          return _summary();
        },
        onOpenAttention: (_, item) async {
          openedItems.add(item);
        },
      );

      final vehicleAttentionRow = find.byKey(
        const Key('compliance-attention-vehicle-10-mot'),
      );
      await _scrollTo(tester, vehicleAttentionRow);
      final vehicleInkWell = find.descendant(
        of: vehicleAttentionRow,
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(vehicleInkWell).onTap, isNotNull);
      await tester.tap(vehicleAttentionRow);
      await tester.pump();
      await tester.pump();

      expect(
        openedItems.single.subjectType,
        FleetComplianceSubjectType.vehicle,
      );
      expect(openedItems.single.subjectId, 10);
      expect(loads, 2);

      final driverAttentionRow = find.byKey(
        const Key('compliance-attention-driver-20-cpc'),
      );
      await _scrollTo(tester, driverAttentionRow);
      await tester.tap(driverAttentionRow);
      await tester.pump();
      await tester.pump();

      expect(openedItems.last.subjectType, FleetComplianceSubjectType.driver);
      expect(openedItems.last.subjectId, 20);
      expect(loads, 3);
    },
  );

  testWidgets(
    'filters attention locally by search metadata and clears filters',
    (tester) async {
      await _pump(tester, () async => _summary());
      expect(find.text('67%'), findsOneWidget);
      await _scrollTo(
        tester,
        find.byKey(const Key('compliance-attention-search')),
      );

      await tester.enterText(
        find.byKey(const Key('compliance-attention-search')),
        '  f10  ',
      );
      await tester.pump();

      expect(find.text('Showing 1 of 3 attention items'), findsOneWidget);
      expect(
        find.byKey(const Key('compliance-attention-vehicle-10-mot')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('compliance-attention-driver-20-cpc')),
        findsNothing,
      );
      await _scrollToTop(tester);
      expect(
        find.byKey(const Key('compliance-status-Expired')),
        findsOneWidget,
      );

      await _scrollTo(
        tester,
        find.byKey(const Key('compliance-attention-clear-filters')),
      );
      await tester.tap(
        find.byKey(const Key('compliance-attention-clear-filters')),
      );
      await tester.pump();

      expect(find.text('Showing 3 of 3 attention items'), findsOneWidget);
      final restoredDriverAttentionRow = find.byKey(
        const Key('compliance-attention-driver-20-cpc'),
      );
      await _scrollTo(tester, restoredDriverAttentionRow);
      expect(restoredDriverAttentionRow, findsOneWidget);
      await _scrollTo(tester, find.text('Fleet Compliance'), delta: -300);
      expect(find.text('67%'), findsOneWidget);
    },
  );

  testWidgets(
    'filters attention by status and subject with a resettable empty state',
    (tester) async {
      await _pump(tester, () async => _summary());
      await _scrollTo(
        tester,
        find.byKey(const Key('compliance-attention-search')),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Drivers'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Expired'));
      await tester.pump();

      expect(
        find.text('No attention items match the current filters.'),
        findsOneWidget,
      );
      expect(find.text('AB12 CDE'), findsNothing);
      expect(find.text('Jane Smith'), findsNothing);

      final clearFilters = find
          .widgetWithText(TextButton, 'Clear filters')
          .last;
      await _scrollTo(tester, clearFilters);
      await tester.tap(clearFilters);
      await tester.pump();

      expect(find.text('Showing 3 of 3 attention items'), findsOneWidget);
    },
  );

  for (final width in [390.0, 700.0, 1280.0]) {
    testWidgets('renders without overflow at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pump(tester, () async => _summary());

      expect(find.text('Fleet Compliance'), findsOneWidget);
      expect(find.byKey(const Key('compliance-status-Valid')), findsOneWidget);
      expect(
        find.byKey(const Key('compliance-status-Due Soon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('compliance-status-Expired')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('compliance-status-Not Recorded')),
        findsOneWidget,
      );
      await _scrollTo(tester, find.text('Needs Attention'));
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(
        find.byKey(const Key('compliance-attention-search')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  Future<FleetComplianceSummary> Function() loadSummary, {
  bool settle = true,
  Future<void> Function(
    BuildContext context,
    FleetComplianceAttentionItem item,
  )?
  onOpenAttention,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ComplianceCentreScreen(
        loadSummary: loadSummary,
        onOpenAttention: onOpenAttention,
      ),
    ),
  );
  await tester.pump();
  if (settle) {
    await tester.pump();
  }
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
}) async {
  final page = find.byKey(const Key('compliance-centre-scroll'));
  final scrollable = find.descendant(
    of: page,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  expect(page, findsOneWidget);
  expect(scrollable, findsOneWidget);
  await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
  await tester.pump();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  final page = find.byKey(const Key('compliance-centre-scroll'));
  final scrollable = find.descendant(
    of: page,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  expect(page, findsOneWidget);
  expect(scrollable, findsOneWidget);
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
}

FleetComplianceSummary _summary({
  List<FleetComplianceAttentionItem>? attentionItems,
}) => FleetComplianceSummary(
  compliancePercentage: 67,
  totalChecks: 6,
  compliantChecks: 4,
  validCount: 1,
  dueSoonCount: 1,
  expiredCount: 1,
  notRecordedCount: 3,
  vehicleCheckCount: 2,
  driverCheckCount: 4,
  attentionItems:
      attentionItems ??
      [
        FleetComplianceAttentionItem(
          subjectType: FleetComplianceSubjectType.vehicle,
          subjectId: 10,
          checkType: FleetComplianceCheckType.mot,
          status: FleetComplianceStatus.expired,
          date: DateTime(2026, 8, 12),
          subjectDisplay: 'AB12 CDE',
          secondaryDisplay: 'F10',
        ),
        FleetComplianceAttentionItem(
          subjectType: FleetComplianceSubjectType.driver,
          subjectId: 20,
          checkType: FleetComplianceCheckType.cpc,
          status: FleetComplianceStatus.dueSoon,
          date: DateTime(2026, 9, 21),
          subjectDisplay: 'Jane Smith',
        ),
        const FleetComplianceAttentionItem(
          subjectType: FleetComplianceSubjectType.driver,
          subjectId: 30,
          checkType: FleetComplianceCheckType.dbs,
          status: FleetComplianceStatus.notRecorded,
          date: null,
          subjectDisplay: 'John Smith',
        ),
      ],
);
