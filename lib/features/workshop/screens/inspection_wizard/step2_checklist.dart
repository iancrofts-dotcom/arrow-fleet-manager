import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_item.dart';
import '../../models/inspection_template_item.dart';
import '../../models/inspection_template_section.dart';
import '../../models/inspection_wizard_data.dart';
import '../../models/repair_job.dart';
import '../../services/checklist_template_service.dart';
import '../../repositories/inspection_template_repository.dart';

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
  late final ImagePicker _imagePicker;
  bool _loadingChecklist = true;

  @override
  void initState() {
    super.initState();

    _templateService = ChecklistTemplateService();
    _imagePicker = ImagePicker();

    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    if (widget.data.checklistItems.isEmpty) {
      final templateId = widget.data.templateId;
      if (templateId == null) {
        widget.data.checklistItems = _templateService.getDefaultTemplate();
      } else {
        final repository = InspectionTemplateRepository();
        final results = await Future.wait([
          repository.getTemplateItems(templateId),
          repository.getTemplateSections(templateId),
        ]);
        final items = results[0] as List<InspectionTemplateItem>;
        final sections = results[1] as List<InspectionTemplateSection>;
        final sectionNames = <int, String>{};
        for (final section in sections) {
          final sectionId = section.id;
          if (sectionId != null) {
            sectionNames[sectionId] = section.title;
          }
        }
        widget.data.checklistItems = items
            .where((item) => item.isActive)
            .map(
              (item) => InspectionChecklistItem(
                id: 'template-${item.id}',
                category: sectionNames[item.sectionId] ?? item.category.name,
                title: item.title,
                description: item.description,
                status: _checklistStatus(item.defaultStatus),
                priority: _checklistPriority(item),
                mandatory: item.mandatory,
                photoRequired: item.photoRequiredOnFail,
                autoCreateRepair: item.autoCreateRepair,
                allowNotes: item.allowNotes,
                responseType: item.responseType,
              ),
            )
            .toList();
      }
    }

    if (!mounted) return;
    setState(() => _loadingChecklist = false);
  }

  ChecklistStatus _checklistStatus(InspectionItemStatus status) {
    switch (status) {
      case InspectionItemStatus.pass:
        return ChecklistStatus.pass;
      case InspectionItemStatus.fail:
        return ChecklistStatus.fail;
      case InspectionItemStatus.advisory:
        return ChecklistStatus.advisory;
      case InspectionItemStatus.notApplicable:
        return ChecklistStatus.pending;
    }
  }

  ChecklistPriority _checklistPriority(InspectionTemplateItem item) {
    if (item.roadworthyImpact == TemplateRoadworthyImpact.notRoadworthy) {
      return ChecklistPriority.critical;
    }

    switch (item.repairPriority) {
      case RepairPriority.low:
        return ChecklistPriority.low;
      case RepairPriority.medium:
        return ChecklistPriority.medium;
      case RepairPriority.high:
        return ChecklistPriority.high;
      case RepairPriority.critical:
        return ChecklistPriority.critical;
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

      item.repairRequired =
          status == ChecklistStatus.fail && item.autoCreateRepair;
    });
  }

  void _setResponse(InspectionChecklistItem item, String value) {
    setState(() {
      item.responseValue = value;
      item.status = value.trim().isEmpty
          ? ChecklistStatus.pending
          : ChecklistStatus.pass;
    });
  }

  void _continue() {
    final incomplete = widget.data.checklistItems.any(
      (item) => item.mandatory && !item.completed,
    );
    final missingPhoto = widget.data.checklistItems.any(
      (item) => item.failed && item.photoRequired && item.photos.isEmpty,
    );

    if (incomplete || missingPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            missingPhoto
                ? 'Attach photo evidence for each failed item that requires it.'
                : 'Complete all mandatory checklist items before continuing.',
          ),
        ),
      );
      return;
    }

    widget.onNext();
  }

  void _setNotes(
    InspectionChecklistItem item,
    String notes,
  ) {
    item.notes = notes;
  }

  // =========================================================================
  // TAKE PHOTO
  // =========================================================================

  Future<void> _takePhoto(
    InspectionChecklistItem item,
  ) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (photo == null) {
        return;
      }

      setState(() {
        item.photos.add(photo.path);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Camera unavailable on this device. '
            'Please choose a photo instead.',
          ),
        ),
      );
    }
  }

  // =========================================================================
  // CHOOSE PHOTO
  // =========================================================================

  Future<void> _choosePhoto(
    InspectionChecklistItem item,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result == null) {
        return;
      }

      final paths = result.files
          .map((file) => file.path)
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toList();

      if (paths.isEmpty) {
        return;
      }

      setState(() {
        item.photos.addAll(paths);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select the photo.',
          ),
        ),
      );
    }
  }

  // =========================================================================
  // REMOVE PHOTO
  // =========================================================================

  void _removePhoto(
    InspectionChecklistItem item,
    String path,
  ) {
    setState(() {
      item.photos.remove(path);
    });
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loadingChecklist) {
      return const Center(child: CircularProgressIndicator());
    }

    final grouped = <String, List<InspectionChecklistItem>>{};

    for (final item in widget.data.checklistItems) {
      grouped.putIfAbsent(
        item.category,
        () => [],
      ).add(item);
    }

    return Column(
      children: [
        // ===================================================================
        // TOP SUMMARY
        // ===================================================================

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
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
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
                          'Check each item, add notes and attach photos.',
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

        // ===================================================================
        // CHECKLIST
        // ===================================================================

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
                      _setStatus(
                        item,
                        status,
                      );
                    },
                    onNotesChanged: (notes) {
                      _setNotes(
                        item,
                        notes,
                      );
                    },
                    onResponseChanged: (value) => _setResponse(item, value),
                    onTakePhoto: () {
                      _takePhoto(item);
                    },
                    onChoosePhoto: () {
                      _choosePhoto(item);
                    },
                    onRemovePhoto: (path) {
                      _removePhoto(
                        item,
                        path,
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),
              ],
            ],
          ),
        ),

        // ===================================================================
        // FOOTER
        // ===================================================================

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
                onPressed: _continue,
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

// =============================================================================
// STATUS SUMMARY
// =============================================================================

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
    final scheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(20),
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

// =============================================================================
// CHECKLIST CARD
// =============================================================================

class _ChecklistCard extends StatefulWidget {
  final InspectionChecklistItem item;
  final ValueChanged<ChecklistStatus>
      onStatusChanged;
  final ValueChanged<String>
      onNotesChanged;
  final ValueChanged<String> onResponseChanged;
  final VoidCallback onTakePhoto;
  final VoidCallback onChoosePhoto;
  final ValueChanged<String> onRemovePhoto;

  const _ChecklistCard({
    required this.item,
    required this.onStatusChanged,
    required this.onNotesChanged,
    required this.onResponseChanged,
    required this.onTakePhoto,
    required this.onChoosePhoto,
    required this.onRemovePhoto,
  });

  @override
  State<_ChecklistCard> createState() =>
      _ChecklistCardState();
}

class _ChecklistCardState
    extends State<_ChecklistCard> {
  late final TextEditingController
      _notesController;
  late final TextEditingController _responseController;

  bool _showNotes = false;
  bool _showPhotos = false;

  @override
  void initState() {
    super.initState();

    _notesController =
        TextEditingController(
      text: widget.item.notes,
    );
    _responseController = TextEditingController(
      text: widget.item.responseValue,
    );

    _showNotes =
        widget.item.notes.trim().isNotEmpty;

    _showPhotos =
        widget.item.photos.isNotEmpty;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  void _toggleNotes() {
    setState(() {
      _showNotes = !_showNotes;
    });
  }

  void _togglePhotos() {
    setState(() {
      _showPhotos = !_showPhotos;
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
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: widget.item.completed
              ? scheme.primary
                  .withValues(alpha: 0.45)
              : scheme.outlineVariant,
          width:
              widget.item.completed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          // =================================================================
          // HEADER
          // =================================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      scheme.primaryContainer,
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
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.item.mandatory
                          ? 'Mandatory inspection item'
                          : 'Optional inspection item',
                      style: theme.textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                            scheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.item.description != null &&
                        widget.item.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.item.description!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),

              if (widget.item.photos.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        scheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.item.photos.length}',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================================
          // RESPONSE
          // =================================================================

          if (widget.item.responseType == InspectionResponseType.text ||
              widget.item.responseType == InspectionResponseType.numeric)
            TextField(
              controller: _responseController,
              keyboardType: widget.item.responseType ==
                      InspectionResponseType.numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: widget.item.responseType == InspectionResponseType.numeric
                    ? 'Numeric response'
                    : 'Response',
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.onResponseChanged,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
              _StatusButton(
                label: widget.item.responseType ==
                        InspectionResponseType.yesNoNotApplicable
                    ? 'YES'
                    : 'PASS',
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
                label: widget.item.responseType ==
                        InspectionResponseType.yesNoNotApplicable
                    ? 'NO'
                    : 'ADVISORY',
                icon: widget.item.responseType ==
                        InspectionResponseType.yesNoNotApplicable
                    ? Icons.close
                    : Icons.warning_amber,
                selected:
                    widget.item.status ==
                        (widget.item.responseType ==
                                InspectionResponseType.yesNoNotApplicable
                            ? ChecklistStatus.fail
                            : ChecklistStatus.advisory),
                onPressed: () {
                  widget.onStatusChanged(
                    widget.item.responseType ==
                            InspectionResponseType.yesNoNotApplicable
                        ? ChecklistStatus.fail
                        : ChecklistStatus.advisory,
                  );
                },
              ),

              _StatusButton(
                label: 'N/A',
                icon: Icons.remove_circle_outline,
                selected:
                    widget.item.status ==
                        ChecklistStatus.notApplicable,
                onPressed: () {
                  widget.onStatusChanged(
                    ChecklistStatus.notApplicable,
                  );
                },
              ),
              if (widget.item.responseType ==
                  InspectionResponseType.passFailNotApplicable)
                _StatusButton(
                  label: 'DEFECT',
                  icon: Icons.close,
                  selected: widget.item.status == ChecklistStatus.fail,
                  onPressed: () => widget.onStatusChanged(ChecklistStatus.fail),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // =================================================================
          // NOTES / PHOTO ACTIONS
          // =================================================================

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.item.allowNotes)
                OutlinedButton.icon(
                  onPressed: _toggleNotes,
                  icon: Icon(
                    _showNotes
                        ? Icons.expand_less
                        : Icons.edit_note_outlined,
                  ),
                  label: Text(
                    _showNotes
                        ? 'Hide notes'
                        : widget.item.notes.trim().isEmpty
                            ? 'Add note'
                            : 'Edit note',
                  ),
                ),

              OutlinedButton.icon(
                onPressed: _togglePhotos,
                icon: Icon(
                  _showPhotos
                      ? Icons.expand_less
                      : Icons.photo_library_outlined,
                ),
                label: Text(
                  widget.item.photos.isEmpty
                      ? 'Photos'
                      : 'Photos (${widget.item.photos.length})',
                ),
              ),
            ],
          ),

          // =================================================================
          // NOTES
          // =================================================================

          if (_showNotes) ...[
            const SizedBox(height: 12),

            TextField(
              controller:
                  _notesController,
              minLines: 3,
              maxLines: 6,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration:
                  InputDecoration(
                labelText:
                    'Technician notes',
                hintText:
                    'Enter observations, measurements '
                    'or additional information...',
                alignLabelWithHint:
                    true,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onChanged:
                  widget.onNotesChanged,
            ),
          ],

          // =================================================================
          // PHOTOS
          // =================================================================

          if (_showPhotos) ...[
            const SizedBox(height: 12),

            Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    scheme.surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color:
                      scheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Inspection photographs',
                          style: theme
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ---------------------------------------------------------
                  // PHOTO BUTTONS
                  // ---------------------------------------------------------

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed:
                            widget.onTakePhoto,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                        ),
                        label:
                            const Text(
                          'Take Photo',
                        ),
                      ),

                      OutlinedButton.icon(
                        onPressed:
                            widget.onChoosePhoto,
                        icon: const Icon(
                          Icons.folder_open_outlined,
                        ),
                        label:
                            const Text(
                          'Choose Photo',
                        ),
                      ),
                    ],
                  ),

                  // ---------------------------------------------------------
                  // PHOTO PREVIEW
                  // ---------------------------------------------------------

                  if (widget.item.photos
                      .isNotEmpty) ...[
                    const SizedBox(height: 14),

                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        scrollDirection:
                            Axis.horizontal,
                        itemCount:
                            widget.item.photos
                                .length,
                        separatorBuilder:
                            (_, _) =>
                                const SizedBox(
                          width: 10,
                        ),
                        itemBuilder:
                            (context, index) {
                          final path =
                              widget.item.photos[
                                  index];

                          return _PhotoThumbnail(
                            path: path,
                            onRemove: () {
                              widget
                                  .onRemovePhoto(
                                path,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // =================================================================
          // DEFECT MESSAGE
          // =================================================================

          if (widget.item.status ==
              ChecklistStatus.fail) ...[
            const SizedBox(height: 12),

            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    scheme.errorContainer,
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
                      style: theme
                          .textTheme
                          .bodySmall
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

// =============================================================================
// PHOTO THUMBNAIL
// =============================================================================

class _PhotoThumbnail extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _PhotoThumbnail({
    required this.path,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(12),
          child: SizedBox(
            width: 110,
            height: 110,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        Positioned(
          top: 5,
          right: 5,
          child: Material(
            color: Colors.black54,
            borderRadius:
                BorderRadius.circular(20),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(20),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// STATUS BUTTON
// =============================================================================

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
