import 'package:arrow_fleet_manager/app/router.dart';
import 'package:arrow_fleet_manager/shared/widgets/app_shell.dart';
import 'package:arrow_fleet_manager/shared/widgets/fleetiq_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'mobile AppShell shows permitted destinations directly without redundant More',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final route = ValueNotifier<String>(AppRouter.dashboard);
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: AppShell(
            navigatorKey: navigatorKey,
            currentRoute: route,
            isAuthenticated: true,
            child: const Scaffold(body: Text('Feature content')),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('compact-bottom-navigation')),
        findsOneWidget,
      );
      expect(find.byType(FleetIqBrand), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      // Build 17.4.3 intentionally removes More when every permitted module fits
      // directly in the compact navigation. With no role installed in this
      // isolated shell test, Dashboard is the only permitted destination.
      expect(find.text('More'), findsNothing);
      expect(find.text('Feature content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mobile AppShell does not create a More menu when there is no overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final route = ValueNotifier<String>(AppRouter.dashboard);
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: AppShell(
            navigatorKey: navigatorKey,
            currentRoute: route,
            isAuthenticated: true,
            child: const Scaffold(body: Text('Feature content')),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('compact-bottom-navigation')),
        findsOneWidget,
      );
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('More'), findsNothing);
      expect(find.text('Fleet'), findsNothing);
      expect(find.text('Drivers'), findsNothing);
      expect(find.text('Workshop'), findsNothing);
      expect(find.text('Feature content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('AppShell has no framework exception at responsive widths', (
    tester,
  ) async {
    final route = ValueNotifier<String>(AppRouter.dashboard);
    final navigatorKey = GlobalKey<NavigatorState>();

    for (final size in const [Size(700, 900), Size(1000, 800)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            navigatorKey: navigatorKey,
            currentRoute: route,
            isAuthenticated: true,
            child: const Scaffold(body: Text('Feature content')),
          ),
        ),
      );
      await tester.pump();
      if (size.width < 960) {
        expect(
          find.byKey(const Key('compact-bottom-navigation')),
          findsOneWidget,
        );
      } else {
        expect(find.byType(FleetIqBrand), findsOneWidget);
        expect(
          find.byKey(const Key('compact-bottom-navigation')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('desktop AppShell renders navigation without Material errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final route = ValueNotifier<String>(AppRouter.dashboard);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          navigatorKey: navigatorKey,
          currentRoute: route,
          isAuthenticated: true,
          child: const Scaffold(body: Text('Feature content')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FleetIqBrand), findsOneWidget);
    expect(find.text('FleetIQ'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Feature content'), findsOneWidget);
    expect(
      find.byKey(const Key('sidebar-destination-/dashboard')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
