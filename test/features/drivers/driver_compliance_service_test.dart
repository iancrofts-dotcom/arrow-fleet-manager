import 'package:arrow_fleet_manager/features/drivers/services/driver_compliance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = DriverComplianceService();

  test('DBS status distinguishes missing, valid, due soon, and expired', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    expect(service.status(null), 'Not Recorded');
    expect(service.status(today.subtract(const Duration(days: 1))), 'Expired');
    expect(service.status(today.add(const Duration(days: 29))), 'Due Soon');
    expect(service.status(today.add(const Duration(days: 30))), 'Due Soon');
    expect(service.status(today.add(const Duration(days: 31))), 'Valid');
  });

  test('due-soon DBS remains compliant while missing and expired DBS do not', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    expect(service.isCompliant(today.add(const Duration(days: 1))), isTrue);
    expect(service.isCompliant(null), isFalse);
    expect(service.isCompliant(today.subtract(const Duration(days: 1))), isFalse);
  });
}
