import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_inspection_item.dart';
import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/backend_workshop_writes.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';
import 'central_workshop_repair_job_details_screen.dart';

class CentralWorkshopInspectionDetailsData {
  const CentralWorkshopInspectionDetailsData({
    required this.inspection,
    required this.items,
    required this.repairJobs,
  });

  final BackendWorkshopInspection inspection;
  final List<BackendWorkshopInspectionItem> items;
  final List<BackendWorkshopRepairJob> repairJobs;
}

class CentralWorkshopInspectionDetailsScreen extends StatefulWidget {
  const CentralWorkshopInspectionDetailsScreen({
    super.key,
    required this.inspectionId,
    required this.repository,
    this.loadData,
  });

  final String inspectionId;
  final BackendWorkshopRepository repository;
  final Future<CentralWorkshopInspectionDetailsData> Function()? loadData;

  @override
  State<CentralWorkshopInspectionDetailsScreen> createState() =>
      _CentralWorkshopInspectionDetailsScreenState();
}

class _CentralWorkshopInspectionDetailsScreenState
    extends State<CentralWorkshopInspectionDetailsScreen> {
  late Future<CentralWorkshopInspectionDetailsData> _future;
  bool _working = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() => _future = (widget.loadData ?? _load)();

  Future<CentralWorkshopInspectionDetailsData> _load() async {
    final inspection = await widget.repository.getInspection(
      widget.inspectionId,
    );
    if (inspection == null) {
      throw StateError('Workshop inspection was not found.');
    }
    final items = await widget.repository.listInspectionItems(
      widget.inspectionId,
    );
    final repairs = await widget.repository.listRepairJobs(
      inspectionId: widget.inspectionId,
    );
    return CentralWorkshopInspectionDetailsData(
      inspection: inspection,
      items: items,
      repairJobs: repairs,
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(_reload);
    await _future;
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Workshop update failed: $error')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  bool _canOperate(BackendWorkshopInspection inspection) {
    final permissions = PermissionService.instance;
    if (permissions.canManageWorkshop) return true;
    return permissions.isTechnician &&
        inspection.technicianProfileId == AuthService.instance.currentUserId;
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Inspection details',
    subtitle: 'Central Workshop operational record',
    child: FutureBuilder<CentralWorkshopInspectionDetailsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading inspection...');
        }
        if (snapshot.hasError || snapshot.data == null) {
          return AppErrorState(
            title: 'Unable to load inspection',
            message: 'The central Workshop record could not be loaded.',
            onRetry: _refresh,
          );
        }

        final data = snapshot.data!;
        final inspection = data.inspection;
        final locked =
            inspection.status == 'signedOff' ||
            inspection.status == 'cancelled';
        final canOperate = _canOperate(inspection) && !locked;
        final permissions = PermissionService.instance;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SectionCard(
                title: inspection.inspectionNumber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(
                      'Vehicle',
                      '${inspection.registration} · ${inspection.fleetNumber}',
                    ),
                    _line('Type', _label(inspection.inspectionType)),
                    _line('Status', _label(inspection.status)),
                    _line('Result', _label(inspection.overallResult)),
                    _line('Vehicle status', _label(inspection.vehicleStatus)),
                    _line(
                      'Technician',
                      inspection.technicianName.isEmpty
                          ? 'Not assigned'
                          : inspection.technicianName,
                    ),
                    _line('Mileage', '${inspection.mileage}'),
                    _line('Score', '${inspection.inspectionScore}%'),
                    _line(
                      'Critical failures',
                      '${inspection.criticalFailures}',
                    ),
                    _line('Advisories', '${inspection.advisories}'),
                    _line('Repairs required', '${inspection.repairsRequired}'),
                    if (inspection.notes.trim().isNotEmpty)
                      _line('Notes', inspection.notes),
                  ],
                ),
              ),
              if (permissions.canManageWorkshop && !locked) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _working
                        ? null
                        : () => _assignInspectionTechnician(inspection),
                    icon: const Icon(Icons.engineering_outlined),
                    label: const Text('Assign technician'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _CentralWorkshopChecklist(
                items: data.items,
                enabled: canOperate && !_working,
                onStatusChanged: _quickSaveChecklistStatus,
                onNotesSaved: _quickSaveChecklistNotes,
                onAddPhoto: _addPhoto,
                onViewEvidence: _showEvidence,
                onCreateRepair: (item) => _newRepair(
                  data.items,
                  preselectedItemId: item.id,
                  suggestedTitle: item.title,
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Repair jobs',
                child: Column(
                  children: [
                    if (data.repairJobs.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No repair jobs are linked to this inspection.',
                        ),
                      ),
                    for (final job in data.repairJobs)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.build_circle_outlined),
                        title: Text('${job.jobNumber} · ${job.title}'),
                        subtitle: Text(
                          '${_label(job.priority)} · ${_label(job.status)}${job.technicianName.isEmpty ? '' : ' · ${job.technicianName}'}',
                        ),
                        trailing: job.partsRequired
                            ? const Icon(Icons.inventory_2_outlined)
                            : null,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CentralWorkshopRepairJobDetailsScreen(
                                    job: job,
                                    repository: widget.repository,
                                  ),
                            ),
                          );
                          await _refresh();
                        },
                      ),
                    if (canOperate) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: _working
                              ? null
                              : () => _newRepair(data.items),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add repair job'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canOperate ||
                  (permissions.canSignOffInspection &&
                      inspection.status == 'completed')) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (canOperate)
                      FilledButton.icon(
                        onPressed: _working
                            ? null
                            : () => _run(
                                () => widget.repository.completeInspection(
                                  widget.inspectionId,
                                ),
                                'Inspection recalculated.',
                              ),
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Complete inspection'),
                      ),
                    if (permissions.canSignOffInspection &&
                        inspection.status == 'completed')
                      FilledButton.icon(
                        onPressed: _working
                            ? null
                            : () => _run(
                                () => widget.repository.signOffInspection(
                                  widget.inspectionId,
                                ),
                                'Inspection signed off.',
                              ),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Sign off inspection'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    ),
  );

  Future<void> _quickSaveChecklistStatus(
    BackendWorkshopInspectionItem item,
    String status,
  ) async {
    final repairRequired = status == 'fail' && item.autoCreateRepair;
    await _run(() async {
      await widget.repository.saveInspectionItem(
        BackendWorkshopInspectionItemWrite(
          id: item.id,
          inspectionId: item.inspectionId,
          category: item.category,
          sectionTitle: item.sectionTitle,
          title: item.title,
          responseType: item.responseType,
          responseValue: item.responseValue,
          status: status,
          mandatory: item.mandatory,
          repairRequired: repairRequired,
          notes: item.notes,
          displayOrder: item.displayOrder,
        ),
      );
    }, '${item.title}: ${_label(status)}');
  }

  Future<void> _quickSaveChecklistNotes(
    BackendWorkshopInspectionItem item,
    String notes,
  ) async {
    await _run(() async {
      await widget.repository.saveInspectionItem(
        BackendWorkshopInspectionItemWrite(
          id: item.id,
          inspectionId: item.inspectionId,
          category: item.category,
          sectionTitle: item.sectionTitle,
          title: item.title,
          responseType: item.responseType,
          responseValue: item.responseValue,
          status: item.status,
          mandatory: item.mandatory,
          repairRequired: item.repairRequired,
          notes: notes.trim(),
          displayOrder: item.displayOrder,
        ),
      );
    }, 'Inspection notes saved.');
  }

  Future<void> _addPhoto(BackendWorkshopInspectionItem item) async {
    final source = await _choosePhotoSource();
    if (source == null || !mounted) {
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (picked == null || !mounted) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      return;
    }
    if (bytes.length > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo must be 10 MB or smaller.')),
        );
      }
      return;
    }
    final contentType = picked.mimeType ?? _imageContentType(picked.name);
    await _run(
      () => widget.repository.uploadInspectionEvidence(
        inspectionId: widget.inspectionId,
        inspectionItemId: item.id,
        fileName: picked.name,
        bytes: bytes,
        contentType: contentType,
      ),
      'Inspection photo uploaded.',
    );
  }

  Future<ImageSource?> _choosePhotoSource() async {
    final supportsCamera =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!supportsCamera) {
      return ImageSource.gallery;
    }
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEvidence(BackendWorkshopInspectionItem item) async {
    final evidence = await widget.repository.listEvidence(item.id);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${item.title} · photos'),
        content: SizedBox(
          width: 520,
          child: evidence.isEmpty
              ? const Text('No evidence is available.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: evidence.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = evidence[index];
                    return ListTile(
                      leading: const Icon(Icons.image_outlined),
                      title: Text(file.fileName),
                      subtitle: Text(
                        file.uploaderName.isEmpty
                            ? _evidenceDate(file.createdAt)
                            : '${file.uploaderName} · ${_evidenceDate(file.createdAt)}',
                      ),
                      onTap: () async {
                        final url = await widget.repository
                            .createEvidenceSignedUrl(file.storagePath);
                        if (!dialogContext.mounted) {
                          return;
                        }
                        await showDialog<void>(
                          context: dialogContext,
                          builder: (context) => Dialog(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 900,
                                maxHeight: 700,
                              ),
                              child: InteractiveViewer(
                                child: Image.network(
                                  url,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text(
                                      'Photo preview could not be loaded.',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignInspectionTechnician(
    BackendWorkshopInspection inspection,
  ) async {
    final technicians = await widget.repository.listTechnicians();
    if (!mounted) return;
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign technician'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Not assigned'),
          ),
          for (final technician in technicians)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, technician.id),
              child: Text(technician.username),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await _run(
      () => widget.repository.assignInspectionTechnician(
        inspection.id,
        selected.isEmpty ? null : selected,
      ),
      'Technician assignment updated.',
    );
  }

  Future<void> _newRepair(
    List<BackendWorkshopInspectionItem> items, {
    String? preselectedItemId,
    String? suggestedTitle,
  }) async {
    final title = TextEditingController(
      text: suggestedTitle == null ? '' : 'Repair: $suggestedTitle',
    );
    final description = TextEditingController();
    final hours = TextEditingController(text: '0');
    final cost = TextEditingController(text: '0');
    var priority = 'medium';
    var partsRequired = false;
    String? itemId = preselectedItemId;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add repair job'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Repair title'),
                ),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                DropdownButtonFormField<String?>(
                  initialValue: itemId,
                  decoration: const InputDecoration(
                    labelText: 'Checklist item',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not linked'),
                    ),
                    for (final item in items)
                      DropdownMenuItem<String?>(
                        value: item.id,
                        child: Text(item.title),
                      ),
                  ],
                  onChanged: (value) => setLocal(() => itemId = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) =>
                      setLocal(() => priority = value ?? priority),
                ),
                TextField(
                  controller: hours,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated hours',
                  ),
                ),
                TextField(
                  controller: cost,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimated cost',
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: partsRequired,
                  title: const Text('Parts required'),
                  onChanged: (value) =>
                      setLocal(() => partsRequired = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || title.text.trim().isEmpty) {
      return;
    }
    await _run(() async {
      await widget.repository.createRepairJob(
        BackendWorkshopRepairJobCreate(
          inspectionId: widget.inspectionId,
          inspectionItemId: itemId,
          title: title.text.trim(),
          description: description.text.trim(),
          priority: priority,
          partsRequired: partsRequired,
          estimatedHours: double.tryParse(hours.text.trim()) ?? 0,
          estimatedCost: double.tryParse(cost.text.trim()) ?? 0,
        ),
      );
    }, 'Repair job created.');
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _CentralWorkshopChecklist extends StatelessWidget {
  const _CentralWorkshopChecklist({
    required this.items,
    required this.enabled,
    required this.onStatusChanged,
    required this.onNotesSaved,
    required this.onAddPhoto,
    required this.onViewEvidence,
    required this.onCreateRepair,
  });

  final List<BackendWorkshopInspectionItem> items;
  final bool enabled;
  final Future<void> Function(BackendWorkshopInspectionItem, String)
  onStatusChanged;
  final Future<void> Function(BackendWorkshopInspectionItem, String)
  onNotesSaved;
  final Future<void> Function(BackendWorkshopInspectionItem) onAddPhoto;
  final Future<void> Function(BackendWorkshopInspectionItem) onViewEvidence;
  final Future<void> Function(BackendWorkshopInspectionItem) onCreateRepair;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<BackendWorkshopInspectionItem>>{};
    for (final item in items) {
      final section = item.sectionTitle?.trim();
      grouped
          .putIfAbsent(
            section == null || section.isEmpty
                ? _label(item.category)
                : section,
            () => [],
          )
          .add(item);
    }

    final completed = items
        .where((item) => item.status != 'notApplicable')
        .length;
    final passed = items.where((item) => item.status == 'pass').length;
    final advisories = items.where((item) => item.status == 'advisory').length;
    final failed = items.where((item) => item.status == 'fail').length;
    final progress = items.isEmpty ? 0.0 : completed / items.length;

    return SectionCard(
      title: 'Inspection checklist',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Work down the form and tap a result. Add notes or a photo only when needed.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completed / ${items.length}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(value: progress, minHeight: 7),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChecklistCount(
                label: 'Pass',
                value: passed,
                icon: Icons.check_circle_outline,
              ),
              _ChecklistCount(
                label: 'Advisory',
                value: advisories,
                icon: Icons.warning_amber_outlined,
              ),
              _ChecklistCount(
                label: 'Fail',
                value: failed,
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Text('No checklist items are recorded for this inspection.'),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                entry.key,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final item in entry.value) ...[
              _CentralChecklistItemCard(
                key: ValueKey(
                  '${item.id}-${item.status}-${item.notes}-${item.photoCount}',
                ),
                item: item,
                enabled: enabled,
                onStatusChanged: onStatusChanged,
                onNotesSaved: onNotesSaved,
                onAddPhoto: onAddPhoto,
                onViewEvidence: onViewEvidence,
                onCreateRepair: onCreateRepair,
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChecklistCount extends StatelessWidget {
  const _ChecklistCount({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text('$label $value'));
}

class _CentralChecklistItemCard extends StatefulWidget {
  const _CentralChecklistItemCard({
    super.key,
    required this.item,
    required this.enabled,
    required this.onStatusChanged,
    required this.onNotesSaved,
    required this.onAddPhoto,
    required this.onViewEvidence,
    required this.onCreateRepair,
  });

  final BackendWorkshopInspectionItem item;
  final bool enabled;
  final Future<void> Function(BackendWorkshopInspectionItem, String)
  onStatusChanged;
  final Future<void> Function(BackendWorkshopInspectionItem, String)
  onNotesSaved;
  final Future<void> Function(BackendWorkshopInspectionItem) onAddPhoto;
  final Future<void> Function(BackendWorkshopInspectionItem) onViewEvidence;
  final Future<void> Function(BackendWorkshopInspectionItem) onCreateRepair;

  @override
  State<_CentralChecklistItemCard> createState() =>
      _CentralChecklistItemCardState();
}

class _CentralChecklistItemCardState extends State<_CentralChecklistItemCard> {
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final failed = item.status == 'fail';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_itemIcon(item.status)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (item.criticalSafetyItem)
                      Text(
                        'Safety-critical item',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              if (item.photoCount > 0)
                TextButton.icon(
                  onPressed: () => widget.onViewEvidence(item),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text('${item.photoCount}'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ResultButton(
                label: 'Pass',
                icon: Icons.check_circle_outline,
                selected: item.status == 'pass',
                enabled: widget.enabled,
                onPressed: () => widget.onStatusChanged(item, 'pass'),
              ),
              _ResultButton(
                label: 'Advisory',
                icon: Icons.warning_amber_outlined,
                selected: item.status == 'advisory',
                enabled: widget.enabled,
                onPressed: () => widget.onStatusChanged(item, 'advisory'),
              ),
              _ResultButton(
                label: 'Fail',
                icon: Icons.cancel_outlined,
                selected: failed,
                enabled: widget.enabled,
                onPressed: () => widget.onStatusChanged(item, 'fail'),
              ),
              _ResultButton(
                label: 'N/A',
                icon: Icons.remove_circle_outline,
                selected: item.status == 'notApplicable',
                enabled: widget.enabled,
                onPressed: () => widget.onStatusChanged(item, 'notApplicable'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: widget.enabled
                    ? () => setState(() => _notesOpen = !_notesOpen)
                    : null,
                icon: const Icon(Icons.notes_outlined),
                label: Text(
                  item.notes.trim().isEmpty ? 'Add note' : 'Edit note',
                ),
              ),
              TextButton.icon(
                onPressed: widget.enabled
                    ? () => widget.onAddPhoto(item)
                    : null,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Photo'),
              ),
              if (failed)
                FilledButton.tonalIcon(
                  onPressed: widget.enabled
                      ? () => widget.onCreateRepair(item)
                      : null,
                  icon: const Icon(Icons.build_outlined),
                  label: const Text('Create repair'),
                ),
            ],
          ),
          if (failed && item.photoRequiredOnFail && item.photoCount == 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Photo required for this failed item before completion.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (_notesOpen) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              enabled: widget.enabled,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Inspection notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: widget.enabled
                    ? () => widget.onNotesSaved(item, _notesController.text)
                    : null,
                child: const Text('Save note'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

IconData _itemIcon(String status) => switch (status) {
  'fail' => Icons.cancel_outlined,
  'advisory' => Icons.warning_amber_outlined,
  'pass' => Icons.check_circle_outline,
  _ => Icons.remove_circle_outline,
};

String _label(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  if (spaced.isEmpty) {
    return spaced;
  }
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _imageContentType(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

String _evidenceDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
