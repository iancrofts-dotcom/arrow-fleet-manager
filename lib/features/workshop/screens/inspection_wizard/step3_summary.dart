import 'package:flutter/material.dart';

import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_wizard_data.dart';

class Step3Summary extends StatelessWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step3Summary({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  List<InspectionChecklistItem> get items =>
      data.checklistItems;

  int get passed =>
      items.where((i) => i.passed).length;

  int get advisory =>
      items.where((i) => i.advisoryOnly).length;

  int get failed =>
      items.where((i) => i.failed).length;

  int get repairs =>
      items.where((i) => i.repairRequired).length;

  int get completed =>
      items.where((i) => i.completed).length;

  int get score {
    if (items.isEmpty) return 0;

    return ((passed / items.length) * 100).round();
  }

  bool get roadworthy => failed == 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Inspection Summary',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),

                      const SizedBox(height: 24),

                      CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 10,
                      ),

                      const SizedBox(height: 16),

                      Text(
                        '$score%',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall,
                      ),

                      const SizedBox(height: 24),

                      ListTile(
                        leading:
                            const Icon(Icons.check),
                        title:
                            const Text('Passed'),
                        trailing:
                            Text('$passed'),
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.warning,
                        ),
                        title: const Text(
                          'Advisories',
                        ),
                        trailing:
                            Text('$advisory'),
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.cancel,
                        ),
                        title:
                            const Text('Failed'),
                        trailing:
                            Text('$failed'),
                      ),

                      ListTile(
                        leading: const Icon(
                          Icons.build,
                        ),
                        title: const Text(
                          'Repairs Required',
                        ),
                        trailing:
                            Text('$repairs'),
                      ),

                      const Divider(),

                      ListTile(
                        leading: Icon(
                          roadworthy
                              ? Icons.verified
                              : Icons.dangerous,
                          color: roadworthy
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: const Text(
                          'Roadworthy',
                        ),
                        trailing: Text(
                          roadworthy
                              ? 'YES'
                              : 'NO',
                          style: TextStyle(
                            color: roadworthy
                                ? Colors.green
                                : Colors.red,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.arrow_back,
                ),
                label:
                    const Text('Back'),
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed: onNext,
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