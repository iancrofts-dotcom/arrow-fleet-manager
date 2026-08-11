import 'package:flutter/material.dart';

import '../models/inspection_checklist_item.dart';

class ChecklistItemCard extends StatefulWidget {
  final InspectionChecklistItem item;
  final ValueChanged<InspectionChecklistItem>? onChanged;

  const ChecklistItemCard({
    super.key,
    required this.item,
    this.onChanged,
  });

  @override
  State<ChecklistItemCard> createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends State<ChecklistItemCard> {
  late final TextEditingController _notesController;
  bool _notesOpen = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _setStatus(ChecklistStatus status) {
    setState(() {
      widget.item.status = status;
      widget.item.repairRequired = status == ChecklistStatus.fail;
      widget.item.notes = _notesController.text;
    });

    widget.onChanged?.call(widget.item);
  }

  Color get _color {
    switch (widget.item.status) {
      case ChecklistStatus.pass:
        return Colors.green;
      case ChecklistStatus.advisory:
        return Colors.orange;
      case ChecklistStatus.fail:
        return Colors.red;
      case ChecklistStatus.pending:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (widget.item.description?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          widget.item.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(widget.item.priority.name.toUpperCase()),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusButton(
                label: 'PASS',
                icon: Icons.check_rounded,
                color: Colors.green,
                selected: widget.item.status == ChecklistStatus.pass,
                onTap: () => _setStatus(ChecklistStatus.pass),
              ),
              _StatusButton(
                label: 'ADVISORY',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                selected: widget.item.status == ChecklistStatus.advisory,
                onTap: () => _setStatus(ChecklistStatus.advisory),
              ),
              _StatusButton(
                label: 'FAIL',
                icon: Icons.close_rounded,
                color: Colors.red,
                selected: widget.item.status == ChecklistStatus.fail,
                onTap: () => _setStatus(ChecklistStatus.fail),
              ),
              _StatusButton(
                label: 'NOT INSPECTED',
                icon: Icons.remove_red_eye_outlined,
                color: Colors.blueGrey,
                selected: widget.item.status == ChecklistStatus.pending,
                onTap: () => _setStatus(ChecklistStatus.pending),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _notesOpen = !_notesOpen),
                icon: Icon(
                  _notesOpen ? Icons.expand_less : Icons.notes_outlined,
                ),
                label: const Text('Notes'),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Choose Photo'),
              ),
              Chip(
                avatar: const Icon(Icons.photo_library_outlined, size: 16),
                label: Text('${widget.item.photos.length} photos'),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: _notesOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 4,
                      onChanged: (value) {
                        widget.item.notes = value;
                        widget.onChanged?.call(widget.item);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Inspection notes',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (widget.item.repairRequired)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.build_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A repair job will be created for this failed item.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: .55)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
