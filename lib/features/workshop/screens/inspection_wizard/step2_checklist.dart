import 'package:flutter/material.dart';

import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_wizard_data.dart';
import '../../services/checklist_template_service.dart';
import '../../widgets/checklist_item_card.dart';

class Step2Checklist extends StatefulWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step2Checklist({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<Step2Checklist> createState() =>
      _Step2ChecklistState();
}

class _Step2ChecklistState
    extends State<Step2Checklist> {
  late final ChecklistTemplateService _templateService;

  List<InspectionChecklistItem> _items = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _templateService = ChecklistTemplateService();

    _loadChecklist();
  }

  void _loadChecklist() {
    _items = _templateService.getDefaultTemplate();

    setState(() {
      _loading = false;
    });
  }

  int get completedItems =>
      _items.where((i) => i.completed).length;

  int get passedItems =>
      _items.where((i) => i.passed).length;

  int get advisoryItems =>
      _items.where((i) => i.advisoryOnly).length;

  int get failedItems =>
      _items.where((i) => i.failed).length;

  double get progress =>
      _items.isEmpty
          ? 0
          : completedItems / _items.length;

  bool get canContinue =>
      _items
          .where((i) => i.mandatory)
          .every((i) => i.completed);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            8,
          ),
          child: Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inspection Progress',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),

                  const SizedBox(height: 16),

                  LinearProgressIndicator(
                    value: progress,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '$completedItems / ${_items.length} completed',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        label: Text(
                          'Pass $passedItems',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.warning,
                          color: Colors.orange,
                        ),
                        label: Text(
                          'Advisory $advisoryItems',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(
                          Icons.cancel,
                          color: Colors.red,
                        ),
                        label: Text(
                          'Fail $failedItems',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: _items.length,
                  itemBuilder:
                      (context, index) {
                    return ChecklistItemCard(
                      item: _items[index],
                      onChanged: (_) {
                        setState(() {});
                      },
                    );
                  },
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed:
                    widget.onPrevious,
                icon: const Icon(
                  Icons.arrow_back,
                ),
                label: const Text(
                  'Back',
                ),
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed: canContinue
                    ? widget.onNext
                    : null,
                icon: const Icon(
                  Icons.arrow_forward,
                ),
                label: const Text(
                  'Continue',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}