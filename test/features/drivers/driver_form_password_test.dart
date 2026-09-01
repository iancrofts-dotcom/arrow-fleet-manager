import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/widgets/driver_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('create mode displays password and confirmation fields', (
    tester,
  ) async {
    await _pumpDriverForm(tester);
    await _scrollToField(tester, 'Password');

    expect(_field('Password'), findsOneWidget);
    await _scrollToField(tester, 'Confirm Password');
    expect(_field('Confirm Password'), findsOneWidget);
  });

  testWidgets('create mode rejects a seven-character password', (tester) async {
    var submitted = false;
    await _pumpDriverForm(
      tester,
      onSubmit: (_, _) async {
        submitted = true;
      },
    );
    await _fillRequiredCreateFields(tester);
    await _enterText(tester, 'Password', '1234567');
    await _enterText(tester, 'Confirm Password', '1234567');
    await _submit(tester);
    await tester.pump();

    expect(submitted, isFalse);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('create mode accepts an eight-character matching password', (
    tester,
  ) async {
    String? submittedPassword;
    await _pumpDriverForm(
      tester,
      onSubmit: (_, password) async {
        submittedPassword = password;
      },
    );
    await _fillRequiredCreateFields(tester);
    await _enterText(tester, 'Password', '12345678');
    await _enterText(tester, 'Confirm Password', '12345678');
    await _submit(tester);
    await tester.pump();

    expect(submittedPassword, '12345678');
  });

  testWidgets('create mode rejects a mismatched password confirmation', (
    tester,
  ) async {
    var submitted = false;
    await _pumpDriverForm(
      tester,
      onSubmit: (_, _) async {
        submitted = true;
      },
    );
    await _fillRequiredCreateFields(tester);
    await _enterText(tester, 'Password', '12345678');
    await _enterText(tester, 'Confirm Password', '87654321');
    await _submit(tester);
    await tester.pump();

    expect(submitted, isFalse);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('edit mode hides password fields and submits driver data', (
    tester,
  ) async {
    Driver? submittedDriver;
    String? submittedPassword;
    final driver = _driver();
    await _pumpDriverForm(
      tester,
      driver: driver,
      onSubmit: (updatedDriver, password) async {
        submittedDriver = updatedDriver;
        submittedPassword = password;
      },
    );

    await _scrollToField(tester, 'Username');
    expect(_field('Password'), findsNothing);
    expect(_field('Confirm Password'), findsNothing);

    await _enterText(tester, 'Username', 'updated.driver');
    await _submit(tester);
    await tester.pump();

    expect(submittedDriver, driver.copyWith(username: 'updated.driver'));
    expect(submittedPassword, isEmpty);
  });
}

Future<void> _pumpDriverForm(
  WidgetTester tester, {
  Driver? driver,
  Future<void> Function(Driver driver, String password)? onSubmit,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DriverForm(driver: driver, onSubmit: onSubmit ?? (_, _) async {}),
      ),
    ),
  );
}

Future<void> _fillRequiredCreateFields(WidgetTester tester) async {
  await _enterText(tester, 'First Name', 'Ava');
  await _enterText(tester, 'Last Name', 'Driver');
  await _enterText(tester, 'Licence Number', 'LIC-123');
  await _enterText(tester, 'Username', 'ava.driver');
}

Finder _field(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
    description: 'TextField with label "$label"',
  );
}

Future<void> _scrollToField(WidgetTester tester, String label) {
  return _scrollUntilBuilt(tester, _field(label));
}

Future<void> _enterText(WidgetTester tester, String label, String value) async {
  await _scrollToField(tester, label);
  await tester.enterText(_field(label), value);
}

Future<void> _submit(WidgetTester tester) async {
  final submitButton = find.widgetWithText(FilledButton, 'Save Driver');
  await _scrollUntilHitTestable(tester, submitButton);

  final tappableSubmitButton = submitButton.hitTestable();
  expect(tappableSubmitButton, findsOneWidget);
  await tester.tap(tappableSubmitButton);
  await tester.pumpAndSettle();
}

Finder _driverFormList() {
  return find.descendant(
    of: find.byType(DriverForm),
    matching: find.byType(ListView),
  );
}

Future<void> _scrollUntilBuilt(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 12; attempt++) {
    if (target.evaluate().isNotEmpty) {
      expect(target, findsOneWidget);
      await tester.ensureVisible(target);
      await tester.pump();
      return;
    }

    await tester.drag(_driverFormList(), const Offset(0, -300));
    await tester.pump();
  }

  fail('Unable to reveal the requested DriverForm widget.');
}

Future<void> _scrollUntilHitTestable(
  WidgetTester tester,
  Finder target,
) async {
  final list = _driverFormList();
  expect(list, findsOneWidget);

  for (var attempt = 0; attempt < 12; attempt++) {
    final builtCount = target.evaluate().length;
    if (builtCount > 1) {
      fail('Expected the DriverForm submit button to resolve uniquely.');
    }

    if (builtCount == 1 && target.hitTestable().evaluate().length == 1) {
      return;
    }

    await tester.drag(
      list,
      builtCount == 1 ? const Offset(0, -100) : const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }

  fail('Unable to make the DriverForm submit button hit-testable.');
}

Driver _driver() => const Driver(
  id: 7,
  firstName: 'Ava',
  lastName: 'Driver',
  licenceNumber: 'LIC-123',
  username: 'ava.driver',
);
