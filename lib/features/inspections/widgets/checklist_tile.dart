import 'package:flutter/material.dart';

import '../models/inspection_item.dart';
import 'photo_button.dart';

class ChecklistTile extends StatelessWidget {
  final InspectionItem item;
  final ValueChanged<InspectionStatus> onStatusChanged;
  final ValueChanged<String> onNotesChanged;

  const ChecklistTile({
    super.key,
    required this.item,
    required this.onStatusChanged,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFailed = item.status == InspectionStatus.fail;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SegmentedButton<InspectionStatus>(
              segments: const [
                ButtonSegment(
                  value: InspectionStatus.pass,
                  icon: Icon(Icons.check_circle),
                  label: Text("PASS"),
                ),
                ButtonSegment(
                  value: InspectionStatus.fail,
                  icon: Icon(Icons.cancel),
                  label: Text("FAIL"),
                ),
                ButtonSegment(
                  value: InspectionStatus.notApplicable,
                  icon: Icon(Icons.remove_circle),
                  label: Text("N/A"),
                ),
              ],
              selected: {item.status},
              onSelectionChanged: (selection) {
                onStatusChanged(selection.first);
              },
            ),

            if (isFailed) ...[
              const SizedBox(height: 16),

              TextField(
                controller: TextEditingController(text: item.notes)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: item.notes.length),
                  ),
                decoration: const InputDecoration(
                  labelText: "Defect Notes",
                  border: OutlineInputBorder(),
                ),
                onChanged: onNotesChanged,
              ),

              const SizedBox(height: 12),

              const Align(
                alignment: Alignment.centerLeft,
                child: PhotoButton(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}