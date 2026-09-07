import 'package:flutter/material.dart';

import '../../../shared/status_badge.dart';
import '../models/workshop_inspection.dart';

class WorkshopInspectionCard extends StatelessWidget {
  const WorkshopInspectionCard({
    super.key,
    required this.inspection,
    required this.onTap,
  });

  final WorkshopInspection inspection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final driverName = inspection.driverName;
    final submittedBy = driverName != null && driverName.trim().isNotEmpty
        ? 'Driver: $driverName'
        : 'Technician: ${inspection.technicianName}';
    final templateOrType = inspection.templateName?.trim().isNotEmpty == true
        ? inspection.templateName!
        : inspection.inspectionType.label;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final title = Text(
                    inspection.inspectionNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                  final status = _statusBadge(inspection.status);

                  if (constraints.maxWidth < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [title, const SizedBox(height: 8), status],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 12),
                      status,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${inspection.registration} | ${inspection.fleetNumber}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(templateOrType),
              const SizedBox(height: 4),
              Text(submittedBy),
              const SizedBox(height: 4),
              Text('Submitted: ${_dateTimeLabel(inspection.dateStarted)}'),
              const SizedBox(height: 4),
              Text(
                'Result: ${inspection.overallResult.name} | '
                'Repairs: ${inspection.repairsRequired}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  StatusBadge _statusBadge(WorkshopInspectionStatus status) {
    return switch (status) {
      WorkshopInspectionStatus.signedOff => StatusBadge.success('Signed Off'),
      WorkshopInspectionStatus.completed => StatusBadge.success('Completed'),
      WorkshopInspectionStatus.cancelled => StatusBadge.neutral('Cancelled'),
      WorkshopInspectionStatus.awaitingRepair => StatusBadge.warning(
        'Awaiting Repair',
      ),
      WorkshopInspectionStatus.draft => StatusBadge.neutral('Draft'),
      WorkshopInspectionStatus.inProgress => StatusBadge.info('In Progress'),
    };
  }

  String _dateTimeLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
