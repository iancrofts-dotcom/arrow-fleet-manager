import 'package:arrow_fleet_manager/features/reports/widgets/report_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('report preview returns to its source route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportPreviewScreen(
                        title: 'Preview',
                        child: Center(child: Text('Preview content')),
                      ),
                    ),
                  );
                },
                child: const Text('Open preview'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open preview'));
    await tester.pumpAndSettle();

    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Preview content'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open preview'), findsOneWidget);
    expect(find.text('Preview content'), findsNothing);
  });
}
