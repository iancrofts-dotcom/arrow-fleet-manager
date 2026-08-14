import 'package:arrow_fleet_manager/features/workshop/models/inspection_checklist_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/repair_job.dart';
import 'package:arrow_fleet_manager/features/workshop/services/repair_job_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a failed inspection item creates an unassigned open repair job', () {
    final jobs = RepairJobGenerator().generate(
      inspectionId: 42,
      vehicleId: 7,
      vehicleRegistration: 'AB12 CDE',
      items: [
        InspectionChecklistItem(
          id: 'brake-lamp',
          category: 'Exterior',
          title: 'Brake lamp',
          status: ChecklistStatus.fail,
          repairRequired: true,
        ),
      ],
    );

    expect(jobs, hasLength(1));
    expect(jobs.single.status, RepairJobStatus.open);
    expect(jobs.single.technicianId, isNull);
    expect(jobs.single.inspectionId, 42);
  });
}
