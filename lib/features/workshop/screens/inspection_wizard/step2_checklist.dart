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

  List<InspectionChecklistItem> get _items =>
    widget.data.checklistItems;


  @override
  void initState() {
    super.initState();

    _templateService = ChecklistTemplateService();

    _loadChecklist();
  }

  void _loadChecklist() {
  if (widget.data.checklistItems.isEmpty) {
    widget.data.checklistItems =
        _templateService.getDefaultTemplate();
  }
}

    void _updateChecklistItem(InspectionChecklistItem item) {
    setState(() {
      final index = widget.data.checklistItems.indexWhere(
        (i) => i.id == item.id,
      );

      if (index != -1) {
        widget.data.checklistItems[index] = item;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.data.checklistItems.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return ChecklistItemCard(
          item: widget.data.checklistItems[index],
          onChanged: _updateChecklistItem,
        );
      },
    );
  }
}