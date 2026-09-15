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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        leading: const Icon(Icons.fact_check_outlined),
        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${items.length} checks'),
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ChecklistTile(
              item: items[index],
              onStatusChanged: (status) =>
                  onStatusChanged(items[index], status),
              onNotesChanged: (notes) => onNotesChanged(items[index], notes),
            ),
            if (index != items.length - 1)
              Divider(height: 1, color: scheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}
