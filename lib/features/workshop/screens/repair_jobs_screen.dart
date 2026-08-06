import 'package:flutter/material.dart';

import '../models/repair_job.dart';
import '../repositories/workshop_repository.dart';
import 'repair_job_form_screen.dart';

class RepairJobsScreen extends StatefulWidget {
  final int inspectionId;

  const RepairJobsScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  State<RepairJobsScreen> createState() => _RepairJobsScreenState();
}

class _RepairJobsScreenState extends State<RepairJobsScreen> {
  final WorkshopRepository _repository = WorkshopRepository();

  bool _loading = true;
  List<RepairJob> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    final jobs = await _repository.getRepairJobs(widget.inspectionId);

    if (!mounted) return;

    setState(() {
      _jobs = jobs;
      _loading = false;
    });
  }

 Future<void> _openRepairJobForm() async {
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (_) => const RepairJobFormScreen(),
    ),
  );

  if (!mounted || result == null) return;

  final job = RepairJob(
    jobNumber: 'RJ-${DateTime.now().millisecondsSinceEpoch}',
    inspectionId: widget.inspectionId,
    inspectionItemId: 0,
    vehicleId: 0,
    vehicleRegistration: 'UNKNOWN',
    title: result['title'] as String,
    description: result['description'] as String,
    estimatedHours: result['hours'] as double,
    estimatedCost: result['cost'] as double,
    createdAt: DateTime.now(),
  );

  await _repository.createRepairJob(job);

  await _loadJobs();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair Jobs'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _jobs.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = _jobs[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.build),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    job.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Chip(
                                  label: Text(job.status.name),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(job.description),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estimated: ${job.estimatedHours.toStringAsFixed(1)} hrs',
                                ),
                                Text(
                                  '£${job.estimatedCost.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRepairJobForm,
        icon: const Icon(Icons.add),
        label: const Text('New Repair'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.build_circle_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Repair Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Inspection ID: ${widget.inspectionId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            const Text(
              'Repair jobs generated from failed inspection items will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}