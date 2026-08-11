import 'package:flutter/material.dart';

import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_wizard_data.dart';
import '../../models/repair_job.dart';
import '../../services/repair_job_generator.dart';
import '../../widgets/repair_job_card.dart';

class Step4Repairs extends StatefulWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step4Repairs({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step4Repairs> createState() => _Step4RepairsState();
}

class _Step4RepairsState extends State<Step4Repairs> {
  final RepairJobGenerator _generator = RepairJobGenerator();

  List<InspectionChecklistItem> get checklistItems =>
      widget.data.checklistItems;

  List<RepairJob> get repairJobs =>
      widget.data.repairJobs;

  @override
  void initState() {
    super.initState();

    if (widget.data.repairJobs.isEmpty) {
      widget.data.repairJobs = _generator.generate(
        inspectionId: 0,
        vehicleId: widget.data.vehicleId ?? 0,
        vehicleRegistration:
            widget.data.registration ?? '',
        items: checklistItems,
      );
    }
  }

  double get totalEstimatedHours =>
      repairJobs.fold(
        0,
        (sum, job) => sum + job.estimatedHours,
      );

  double get totalEstimatedCost =>
      repairJobs.fold(
        0,
        (sum, job) => sum + job.estimatedCost,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Repair Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.build),
                  title: const Text('Repair Jobs'),
                  trailing: Text('${repairJobs.length}'),
                ),

                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Estimated Hours'),
                  trailing: Text(
                    totalEstimatedHours.toStringAsFixed(1),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.payments),
                  title: const Text('Estimated Cost'),
                  trailing: Text(
                    '£${totalEstimatedCost.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: repairJobs.isEmpty
              ? const Center(
                  child: Text(
                    'No repair jobs generated.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: repairJobs.length,
                  itemBuilder: (context, index) {
                    return RepairJobCard(
                      repairJob: repairJobs[index],
                      onChanged: (job) {
                        setState(() {
                          widget.data.repairJobs[index] =
                              job;
                        });
                      },
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onPrevious,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}