import 'dart:async';

import 'package:arrow_fleet_manager/features/reports/services/report_operation_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prevents overlapping report operations', () async {
    final gate = ReportOperationGate();
    final completion = Completer<void>();
    var calls = 0;

    final first = gate.run(() async {
      calls++;
      await completion.future;
    });

    expect(gate.isRunning, isTrue);
    expect(
      await gate.run(() async {
        calls++;
      }),
      isFalse,
    );
    expect(calls, 1);

    completion.complete();
    expect(await first, isTrue);
    expect(gate.isRunning, isFalse);
  });

  test('releases the gate after a failed operation', () async {
    final gate = ReportOperationGate();

    await expectLater(
      gate.run(() async => throw StateError('write failed')),
      throwsStateError,
    );

    expect(gate.isRunning, isFalse);
    expect(await gate.run(() async {}), isTrue);
  });
}
