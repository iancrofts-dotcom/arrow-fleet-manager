import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inspection types have professional presentation labels', () {
    expect(WorkshopInspectionType.scheduledService.label, 'Scheduled Service');
    expect(WorkshopInspectionType.defectInspection.label, 'Defect Inspection');
    expect(
      WorkshopInspectionType.annualInspection.label,
      'Annual Safety Inspection',
    );
    expect(WorkshopInspectionType.motPreparation.label, 'MOT Preparation');
    expect(WorkshopInspectionType.repairInspection.label, 'Repair Inspection');
    expect(
      WorkshopInspectionType.returnToService.label,
      'Return-to-Service Inspection',
    );
    expect(
      WorkshopInspectionType.driverDailyInspection.label,
      'Driver Daily Walkaround Check',
    );
  });
}
