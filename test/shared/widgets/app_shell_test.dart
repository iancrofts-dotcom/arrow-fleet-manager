import 'package:arrow_fleet_manager/app/router.dart';
import 'package:arrow_fleet_manager/shared/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    expect(find.byKey(const Key('sidebar-official-logo')), findsOneWidget);
    expect(find.text('Fleet Manager'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Feature content'), findsOneWidget);
    expect(
      find.byKey(const Key('sidebar-destination-/dashboard')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
