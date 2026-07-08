import 'package:flutter/material.dart';

import '../models/inspection_item.dart';
import 'checklist_tile.dart';

class ChecklistSection extends StatelessWidget {
  final String title;
  final List<InspectionItem> items;

  final void Function(InspectionItem, InspectionStatus) onStatusChanged;
  final void Function(InspectionItem, String) onNotesChanged;

  const ChecklistSection({
    super.key,
    required this.title,
    required this.items,
    required this.onStatusChanged,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.fact_check),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text("${items.length} checks"),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items
                  .map(
                    (item) => ChecklistTile(
                      item: item,
                      onStatusChanged: (status) =>
                          onStatusChanged(item, status),
                      onNotesChanged: (notes) =>
                          onNotesChanged(item, notes),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}