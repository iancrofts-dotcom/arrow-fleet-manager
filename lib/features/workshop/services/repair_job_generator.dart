import '../models/inspection_checklist_item.dart';
import '../models/repair_job.dart';

class RepairJobGenerator {
  List<RepairJob> generate({
    required int inspectionId,
    required int vehicleId,
    required String vehicleRegistration,
    required List<InspectionChecklistItem> items,
  }) {
    final repairs = <RepairJob>[];

    int sequence = 1;

    for (final item in items) {
      if (!item.repairRequired) {
        continue;
      }

      repairs.add(
        RepairJob(
          jobNumber: _generateJobNumber(
            inspectionId,
            sequence,
          ),
          inspectionId: inspectionId,
          inspectionItemId: sequence,
          vehicleId: vehicleId,
          vehicleRegistration: vehicleRegistration,
          title: item.title,
          description: item.notes.isEmpty
              ? '${item.category} requires repair.'
              : item.notes,
          priority: _priorityFromChecklist(
            item.priority,
          ),
          estimatedHours: _estimatedHours(
            item.category,
          ),
          estimatedCost: 0,
          partsRequired: _partsRequired(
            item.category,
          ),
          roadworthy:
              item.priority != ChecklistPriority.critical,
          createdAt: DateTime.now(),
        ),
      );

      sequence++;
    }

    return repairs;
  }

  String _generateJobNumber(
    int inspectionId,
    int sequence,
  ) {
    final year = DateTime.now().year;

    return 'RJ-$year-$inspectionId-${sequence.toString().padLeft(3, '0')}';
  }

  RepairPriority _priorityFromChecklist(
    ChecklistPriority priority,
  ) {
    switch (priority) {
      case ChecklistPriority.low:
        return RepairPriority.low;

      case ChecklistPriority.medium:
        return RepairPriority.medium;

      case ChecklistPriority.high:
        return RepairPriority.high;

      case ChecklistPriority.critical:
        return RepairPriority.critical;
    }
  }

  double _estimatedHours(String category) {
    switch (category.toLowerCase()) {
      case 'brakes':
        return 2.0;

      case 'tyres':
        return 1.0;

      case 'steering':
        return 2.5;

      case 'suspension':
        return 3.0;

      case 'engine':
        return 5.0;

      case 'lights':
        return 0.5;

      case 'bodywork':
        return 4.0;

      default:
        return 1.0;
    }
  }

  bool _partsRequired(String category) {
    switch (category.toLowerCase()) {
      case 'lights':
        return false;

      case 'bodywork':
        return false;

      default:
        return true;
    }
  }
}