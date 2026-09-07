import 'package:arrow_fleet_manager/shared/status_badge.dart';
import 'package:arrow_fleet_manager/shared/widgets/app_page_scaffold.dart';
import 'package:arrow_fleet_manager/app/theme.dart';
import 'package:arrow_fleet_manager/features/dashboard/widgets/dashboard_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppPageScaffold renders its header, action, and body', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: AppPageScaffold(
          title: 'Fleet Vehicles',
          subtitle: 'Operational fleet overview.',
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
          child: const Center(child: Text('Page body')),
        ),
      ),
    );

    expect(find.text('FleetIQ'), findsOneWidget);
    expect(find.text('Fleet Vehicles'), findsOneWidget);
    expect(find.text('Page body'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('compact headers retain page context without product branding', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    var refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AppPageScaffold(
          title: 'Fleet Calendar',
          subtitle: 'Upcoming fleet, maintenance and compliance dates.',
          actions: [
            OutlinedButton.icon(
              onPressed: () => refreshed = true,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
          child: const SizedBox(),
        ),
      ),
    );

    expect(find.text('FleetIQ'), findsNothing);
    expect(find.text('Fleet Calendar'), findsOneWidget);
    expect(
      find.text('Upcoming fleet, maintenance and compliance dates.'),
      findsOneWidget,
    );
    expect(find.text('Refresh'), findsOneWidget);
    expect(
      tester.widget<Container>(find.byKey(const Key('page-header'))).padding,
      const EdgeInsets.all(12),
    );
    await tester.tap(find.text('Refresh'));
    expect(refreshed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop headers retain the full desktop presentation', (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 800));
    await tester.pumpWidget(
      const MaterialApp(
        home: AppPageScaffold(
          title: 'Fleet Vehicles',
          subtitle: 'Operational fleet overview.',
          child: SizedBox(),
        ),
      ),
    );

    expect(find.text('FleetIQ'), findsOneWidget);
    expect(
      tester.widget<Container>(find.byKey(const Key('page-header'))).padding,
      const EdgeInsets.all(28),
    );
  });

  testWidgets('compact dashboard header retains refresh without branding', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardHeroHeader(
            onRefresh: () {},
            onLogout: () {},
            showBrand: false,
            showLogout: false,
            showIdentity: false,
          ),
        ),
      ),
    );

    expect(find.text('FleetIQ'), findsNothing);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Refresh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppPageScaffold uses a supplied custom header', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppPageScaffold(
          title: 'Hidden default title',
          customHeader: Text('Dashboard custom header'),
          child: Center(child: Text('Custom header body')),
        ),
      ),
    );

    expect(find.text('Dashboard custom header'), findsOneWidget);
    expect(find.text('Custom header body'), findsOneWidget);
    expect(find.text('Hidden default title'), findsNothing);
  });

  testWidgets('shared states render configured text and retry action', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            title: 'Unable to load vehicles',
            message: 'Try again shortly.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Unable to load vehicles'), findsOneWidget);
    expect(find.text('Try again shortly.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('StatusBadge always includes its text label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: StatusBadge.neutral('Not Recorded'))),
    );

    expect(find.text('Not Recorded'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('shared surface variants and themed actions remain usable', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SectionCard(
            title: 'Operational summary',
            variant: SectionCardVariant.dashboardPanel,
            child: FilledButton.icon(
              onPressed: () => invoked = true,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Operational summary'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    expect(invoked, isTrue);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
