import 'package:flutter/material.dart';

import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_wizard_data.dart';
import '../../services/checklist_template_service.dart';

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
  State<Step2Checklist> createState() => _Step2ChecklistState();
}

class _Step2ChecklistState extends State<Step2Checklist> {
  late final ChecklistTemplateService _templateService;

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

  int get _completed {
    return widget.data.checklistItems
        .where((item) => item.completed)
        .length;
  }

  int get _passed {
    return widget.data.checklistItems
        .where((item) => item.passed)
        .length;
  }

  int get _advisory {
    return widget.data.checklistItems
        .where((item) => item.advisoryOnly)
        .length;
  }

  int get _failed {
    return widget.data.checklistItems
        .where((item) => item.failed)
        .length;
  }

  double get _progress {
    if (widget.data.checklistItems.isEmpty) {
      return 0;
    }

    return _completed / widget.data.checklistItems.length;
  }

  void _setStatus(
    InspectionChecklistItem item,
    ChecklistStatus status,
  ) {
    setState(() {
      item.status = status;

      if (status != ChecklistStatus.fail) {
        item.repairRequired = false;
      }
    });
  }

  void _setNotes(
    InspectionChecklistItem item,
    String notes,
  ) {
    item.notes = notes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final grouped = <String, List<InspectionChecklistItem>>{};

    for (final item in widget.data.checklistItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Column(
      children: [
        // ===============================================================
        // TOP SUMMARY
        // ===============================================================
        Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            16,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.fact_check_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inspection Checklist',
                          style: theme.textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Check each item and record the result.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(
                            color:
                                scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_completed / '
                    '${widget.data.checklistItems.length}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusSummary(
                    icon: Icons.check_circle,
                    label: 'Pass',
                    value: _passed,
                  ),
                  _StatusSummary(
                    icon: Icons.warning_amber,
                    label: 'Advisory',
                    value: _advisory,
                  ),
                  _StatusSummary(
                    icon: Icons.cancel,
                    label: 'Defect',
                    value: _failed,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ===============================================================
        // CHECKLIST
        // ===============================================================
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10),
                  child: Text(
                    entry.key,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                for (final item in entry.value) ...[
                  _ChecklistCard(
                    item: item,
                    onStatusChanged: (status) {
                      _setStatus(item, status);
                    },
                    onNotesChanged: (notes) {
                      _setNotes(item, notes);
                    },
                  ),

                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),
              ],
            ],
          ),
        ),

        // ===============================================================
        // FOOTER
        // ===============================================================
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant,
              ),
            ),
          ),
          child: Wrap(
            alignment:
                WrapAlignment.spaceBetween,
            runSpacing: 12,
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onPrevious,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text('Back'),
              ),
              FilledButton.icon(
                onPressed: widget.onNext,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                ),
                label: const Text('Continue'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// STATUS SUMMARY
// ===========================================================================

class _StatusSummary extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatusSummary({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: scheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// CHECKLIST CARD
// ===========================================================================

class _ChecklistCard extends StatefulWidget {
  final InspectionChecklistItem item;
  final ValueChanged<ChecklistStatus>
      onStatusChanged;
  final ValueChanged<String> onNotesChanged;

  const _ChecklistCard({
    required this.item,
    required this.onStatusChanged,
    required this.onNotesChanged,
  });

  @override
  State<_ChecklistCard> createState() =>
      _ChecklistCardState();
}

class _ChecklistCardState
    extends State<_ChecklistCard> {
  late final TextEditingController _notesController;

  bool _showNotes = false;

  @override
  void initState() {
    super.initState();

    _notesController = TextEditingController(
      text: widget.item.notes,
    );

    _showNotes = widget.item.notes.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(
    covariant _ChecklistCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.item.id != widget.item.id) {
      _notesController.text = widget.item.notes;

      _showNotes =
          widget.item.notes.trim().isNotEmpty;
    }
  }

  void _toggleNotes() {
    setState(() {
      _showNotes = !_showNotes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.item.completed
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant,
          width: widget.item.completed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // ---------------------------------------------------------------
          // ITEM HEADER
          // ---------------------------------------------------------------
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  _priorityIcon(
                    widget.item.priority,
                  ),
                  color: scheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: theme.textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.item.mandatory
                          ? 'Mandatory inspection item'
                          : 'Optional inspection item',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color:
                            scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ---------------------------------------------------------------
          // STATUS BUTTONS
          // ---------------------------------------------------------------
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusButton(
                label: 'PASS',
                icon: Icons.check,
                selected:
                    widget.item.status ==
                        ChecklistStatus.pass,
                onPressed: () {
                  widget.onStatusChanged(
                    ChecklistStatus.pass,
                  );
                },
              ),
              _StatusButton(
                label: 'ADVISORY',
                icon: Icons.warning_amber,
                selected:
                    widget.item.status ==
                        ChecklistStatus.advisory,
                onPressed: () {
                  widget.onStatusChanged(
                    ChecklistStatus.advisory,
                  );
                },
              ),
              _StatusButton(
                label: 'DEFECT',
                icon: Icons.close,
                selected:
                    widget.item.status ==
                        ChecklistStatus.fail,
                onPressed: () {
                  widget.onStatusChanged(
                    ChecklistStatus.fail,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------------------------------------------------------------
          // NOTES BUTTON
          // ---------------------------------------------------------------
          OutlinedButton.icon(
            onPressed: _toggleNotes,
            icon: Icon(
              _showNotes
                  ? Icons.expand_less
                  : Icons.edit_note_outlined,
            ),
            label: Text(
              _showNotes
                  ? 'Hide technician notes'
                  : widget.item.notes.trim().isEmpty
                      ? 'Add technician note'
                      : 'Edit technician note',
            ),
          ),

          // ---------------------------------------------------------------
          // NOTES FIELD
          // ---------------------------------------------------------------
          if (_showNotes) ...[
            const SizedBox(height: 12),

            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Technician notes',
                hintText:
                    'Enter any observations, measurements '
                    'or additional information...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(
                    bottom: 48,
                  ),
                  child: Icon(
                    Icons.notes_outlined,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onChanged: widget.onNotesChanged,
            ),
          ],

          // ---------------------------------------------------------------
          // DEFECT MESSAGE
          // ---------------------------------------------------------------
          if (widget.item.status ==
              ChecklistStatus.fail) ...[
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.build_outlined,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Defect recorded. Repair information '
                      'will be available in Step 4.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(
                        color:
                            scheme.onErrorContainer,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _priorityIcon(
    ChecklistPriority priority,
  ) {
    switch (priority) {
      case ChecklistPriority.low:
        return Icons.circle_outlined;
      case ChecklistPriority.medium:
        return Icons.info_outline;
      case ChecklistPriority.high:
        return Icons.priority_high;
      case ChecklistPriority.critical:
        return Icons.warning_amber;
    }
  }
}

// ===========================================================================
// STATUS BUTTON
// ===========================================================================

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return selected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
  }
}