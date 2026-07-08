import 'package:flutter/material.dart';

import '../models/inspection_item.dart';

class ChecklistTile extends StatefulWidget {
  final InspectionItem item;

  const ChecklistTile({
    super.key,
    required this.item,
  });

  @override
  State<ChecklistTile> createState() => _ChecklistTileState();
}

class _ChecklistTileState extends State<ChecklistTile> {
  @override
  Widget build(BuildContext context) {
    final isFailed = widget.item.status == InspectionStatus.fail;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              widget.item.title,
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
                  label: Text("PASS"),
                  icon: Icon(Icons.check_circle),
                ),

                ButtonSegment(
                  value: InspectionStatus.fail,
                  label: Text("FAIL"),
                  icon: Icon(Icons.cancel),
                ),

                ButtonSegment(
                  value: InspectionStatus.notApplicable,
                  label: Text("N/A"),
                  icon: Icon(Icons.remove_circle),
                ),
              ],

              selected: {widget.item.status},

              onSelectionChanged: (selection) {
                setState(() {
                  widget.item.status = selection.first;
                });
              },
            ),

            if (isFailed) ...[
              const SizedBox(height: 16),

              TextField(
                decoration: const InputDecoration(
                  labelText: "Defect Notes",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  widget.item.notes = value;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}