import 'package:flutter/material.dart';

import '../models/inspection_item.dart';
import '../repositories/workshop_repository.dart';
import '../models/workshop_inspection.dart';
import 'workshop_summary_screen.dart';


class WorkshopChecklistScreen extends StatefulWidget {
  final int inspectionId;

  const WorkshopChecklistScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  State<WorkshopChecklistScreen> createState() =>
      _WorkshopChecklistScreenState();
}

class _WorkshopChecklistScreenState
    extends State<WorkshopChecklistScreen> {
  final WorkshopRepository _repository = WorkshopRepository();

  bool _loading = true;

  List<InspectionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _repository.getInspectionItems(
      widget.inspectionId,
    );

    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
    });
  }



  Future<void> _updateItem(
    InspectionItem item,
    InspectionItemStatus status,
  ) async {
    final updated = item.copyWith(
      status: status,
      repairRequired: status == InspectionItemStatus.fail,
    );

    await _repository.updateInspectionItem(updated);

    await _loadItems();
  }

  int get _completed =>
      _items.where(
        (e) => e.status != InspectionItemStatus.notApplicable,
      ).length;

int get _passed =>
    _items.where(
      (e) => e.status == InspectionItemStatus.pass,
    ).length;

int get _advisories =>
    _items.where(
      (e) => e.status == InspectionItemStatus.advisory,
    ).length;

int get _failed =>
    _items.where(
      (e) => e.status == InspectionItemStatus.fail,
    ).length;

double get _score =>
    _items.isEmpty
        ? 0
        : (_passed / _items.length) * 100;

Future<void> _completeInspection() async {
  final inspection =
      await _repository.getInspection(widget.inspectionId);

  if (inspection == null) return;

  final result = _failed > 0
      ? InspectionResult.fail
      : _advisories > 0
          ? InspectionResult.advisory
          : InspectionResult.pass;

  final updated = inspection.copyWith(
    status: WorkshopInspectionStatus.completed,
    overallResult: result,
    inspectionScore: _score.round(),
    criticalFailures: _failed,
    advisories: _advisories,
    repairsRequired: _failed,
    updatedAt: DateTime.now(),
  );

  await _repository.updateInspection(updated);

  if (!mounted) return;

  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => WorkshopSummaryScreen(
      inspectionId: widget.inspectionId,
    ),
  ),
);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Checklist'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(Icons.fact_check),
                    title: Text(
  'Progress $_completed / ${_items.length}',
),

subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const SizedBox(height: 8),

    LinearProgressIndicator(
      value: _items.isEmpty
          ? 0
          : _completed / _items.length,
    ),

    const SizedBox(height: 12),

    Text(
      'Pass: $_passed   '
      'Advisory: $_advisories   '
      'Fail: $_failed',
    ),

    Text(
      'Score: ${_score.toStringAsFixed(0)}%',
    ),
  ],
),
                  
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text(
                                      'Pass',
                                    ),
                                    selected:
                                        item.status ==
                                            InspectionItemStatus
                                                .pass,
                                    onSelected: (_) =>
                                        _updateItem(
                                      item,
                                      InspectionItemStatus
                                          .pass,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text(
                                      'Advisory',
                                    ),
                                    selected:
                                        item.status ==
                                            InspectionItemStatus
                                                .advisory,
                                    onSelected: (_) =>
                                        _updateItem(
                                      item,
                                      InspectionItemStatus
                                          .advisory,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text(
                                      'Fail',
                                    ),
                                    selected:
                                        item.status ==
                                            InspectionItemStatus
                                                .fail,
                                    onSelected: (_) =>
                                        _updateItem(
                                      item,
                                      InspectionItemStatus
                                          .fail,
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
                              
              
                
                ),
Padding(
  padding: const EdgeInsets.all(16),
  child: SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _completeInspection,
      icon: const Icon(Icons.check_circle),
      label: const Text('Complete Inspection'),
    ),
  ),
),

              ],
            ),
    );
  }
}