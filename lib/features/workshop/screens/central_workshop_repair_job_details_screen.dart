import 'dart:async';

import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_evidence.dart';
import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repair_job.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/backend_workshop_writes.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/fleetiq_document_viewer.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';
import 'central_workshop_job_card_viewer_screen.dart';

class CentralWorkshopRepairJobDetailsScreen extends StatefulWidget {
  const CentralWorkshopRepairJobDetailsScreen({
    super.key,
    required this.job,
    required this.repository,
  });

  final BackendWorkshopRepairJob job;
  final BackendWorkshopRepository repository;

  @override
  State<CentralWorkshopRepairJobDetailsScreen> createState() =>
      _CentralWorkshopRepairJobDetailsScreenState();
}

class _CentralWorkshopRepairJobDetailsScreenState
    extends State<CentralWorkshopRepairJobDetailsScreen> {
  late BackendWorkshopRepairJob _job;
  BackendWorkshopInspection? _inspection;
  List<BackendWorkshopEvidence> _evidence = const [];
  Timer? _timer;
  bool _loading = true;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final jobs = await widget.repository.listRepairJobs(
        inspectionId: _job.inspectionId,
      );
      final fresh = jobs.where((row) => row.id == _job.id).firstOrNull;
      final inspection = await widget.repository.getInspection(
        _job.inspectionId,
      );
      var evidence = <BackendWorkshopEvidence>[];
      final itemId = _job.inspectionItemId;
      if (itemId != null) {
        evidence = await widget.repository.listEvidence(itemId);
      }
      if (!mounted) return;
      setState(() {
        if (fresh != null) _job = fresh;
        _inspection = inspection;
        _evidence = evidence;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load full job card: $error')),
        );
      }
    }
  }

  bool get _isAssignedTechnician =>
      PermissionService.instance.isTechnician &&
      _job.technicianProfileId == AuthService.instance.currentUserId;

  bool get _isManager => PermissionService.instance.canManageWorkshop;

  int get _stageIndex {
    switch (_job.status) {
      case 'completed':
        return 3;
      case 'awaitingInspection':
        return 2;
      case 'inProgress':
      case 'awaitingParts':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _startRepair() => _updateStatus('inProgress');

  Future<void> _resumeRepair() => _updateStatus('inProgress');

  Future<void> _markAwaitingParts() => _editRepair(
    targetStatus: 'awaitingParts',
    title: 'Save work and wait for parts',
    actionLabel: 'Await parts',
  );

  Future<void> _completeRepair() => _editRepair(
    targetStatus: 'awaitingInspection',
    title: 'Complete repair',
    actionLabel: 'Submit for sign-off',
    requireWorkNotes: true,
    closeOnSuccess: true,
  );

  Future<void> _editProgress() => _editRepair(
    targetStatus: _job.status == 'assigned' ? 'inProgress' : _job.status,
    title: '${_job.jobNumber} · Update repair',
    actionLabel: 'Save progress',
  );

  Future<void> _editRepair({
    required String targetStatus,
    required String title,
    required String actionLabel,
    bool requireWorkNotes = false,
    bool closeOnSuccess = false,
  }) async {
    final hours = TextEditingController(text: _job.actualHours.toString());
    final cost = TextEditingController(text: _job.actualCost.toString());
    final work = TextEditingController(text: _job.workNotes);
    final parts = TextEditingController(text: _job.partsNotes);
    final mileage = TextEditingController(
      text:
          _job.technicianMileage?.toString() ??
          _inspection?.mileage.toString() ??
          '',
    );
    var partsRequired = _job.partsRequired;
    var roadworthy = _job.roadworthy;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: mileage,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current mileage / odometer',
                    helperText:
                        'The original inspection mileage is preserved separately.',
                  ),
                ),
                TextField(
                  controller: work,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Work carried out / repair notes',
                  ),
                ),
                TextField(
                  controller: parts,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Parts / waiting parts notes',
                  ),
                ),
                TextField(
                  controller: hours,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Actual labour hours',
                  ),
                ),
                TextField(
                  controller: cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Actual cost'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: partsRequired,
                  title: const Text('Parts required'),
                  onChanged: (value) =>
                      setLocal(() => partsRequired = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: roadworthy,
                  title: const Text('Roadworthy after repair'),
                  onChanged: (value) =>
                      setLocal(() => roadworthy = value ?? false),
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
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    final technicianMileage = int.tryParse(mileage.text.trim());
    if (mileage.text.trim().isNotEmpty &&
        (technicianMileage == null || technicianMileage <= 0)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid current mileage.')),
      );
      return;
    }
    if (requireWorkNotes && work.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add the work carried out before completing the repair.',
          ),
        ),
      );
      return;
    }

    final updated = await _run(
      () => widget.repository.updateRepairJob(
        _job.id,
        BackendWorkshopRepairJobUpdate(
          status: targetStatus,
          partsRequired: partsRequired,
          actualHours: double.tryParse(hours.text.trim()) ?? 0,
          actualCost: double.tryParse(cost.text.trim()) ?? 0,
          roadworthy: roadworthy,
          workNotes: work.text.trim(),
          partsNotes: parts.text.trim(),
          technicianMileage: technicianMileage,
        ),
      ),
    );
    if (updated && closeOnSuccess && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _updateStatus(String status) async {
    await _run(
      () => widget.repository.updateRepairJob(
        _job.id,
        BackendWorkshopRepairJobUpdate(
          status: status,
          partsRequired: _job.partsRequired,
          actualHours: _job.actualHours,
          actualCost: _job.actualCost,
          roadworthy: _job.roadworthy,
          workNotes: _job.workNotes,
          partsNotes: _job.partsNotes,
          technicianMileage: _job.technicianMileage,
        ),
      ),
    );
  }

  Future<void> _assignTechnician() async {
    final technicians = await widget.repository.listTechnicians();
    if (!mounted) return;
    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign repair job'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Unassigned'),
          ),
          for (final tech in technicians)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, tech.id),
              child: Text(tech.username),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await _run(
      () => widget.repository.assignRepairTechnician(
        _job.id,
        selected.isEmpty ? null : selected,
      ),
    );
  }

  Future<void> _returnToTechnician() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return repair to Technician?'),
        content: const Text(
          'The job will move back to In Progress so the assigned Technician can update it and resubmit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Return to Technician'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _updateStatus('inProgress');
  }

  Future<void> _signOff() async {
    final hours = TextEditingController(text: _job.actualHours.toString());
    final cost = TextEditingController(text: _job.actualCost.toString());
    final work = TextEditingController(text: _job.workNotes);
    final parts = TextEditingController(text: _job.partsNotes);
    var roadworthy = _job.roadworthy;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Manager sign-off'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Review the repair and confirm it is ready for final closure.',
                ),
                TextField(
                  controller: work,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Final repair notes',
                  ),
                ),
                TextField(
                  controller: parts,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Parts notes'),
                ),
                TextField(
                  controller: hours,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Actual labour hours',
                  ),
                ),
                TextField(
                  controller: cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Actual cost'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: roadworthy,
                  title: const Text('Vehicle is roadworthy'),
                  onChanged: (value) =>
                      setLocal(() => roadworthy = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Approve & sign off'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final updated = await _run(
      () => widget.repository.signOffRepairJob(
        _job.id,
        BackendWorkshopRepairJobUpdate(
          status: 'completed',
          partsRequired: _job.partsRequired,
          actualHours: double.tryParse(hours.text.trim()) ?? 0,
          actualCost: double.tryParse(cost.text.trim()) ?? 0,
          roadworthy: roadworthy,
          workNotes: work.text.trim(),
          partsNotes: parts.text.trim(),
          technicianMileage: _job.technicianMileage,
        ),
      ),
    );
    if (updated && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openJobCard() async {
    if (_working || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CentralWorkshopJobCardViewerScreen(
          job: _job,
          inspection: _inspection,
          evidence: _evidence,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (_working) return false;
    setState(() => _working = true);
    try {
      await action();
      await _load();
      if (!mounted) return true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workshop job updated.')));
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Workshop update failed: $error')));
      return false;
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canWork = _isManager || _isAssignedTechnician;
    final inspection = _inspection;
    return AppPageScaffold(
      title: 'Job Card ${_job.jobNumber}',
      subtitle: '${_job.vehicleRegistration} · ${_label(_job.status)}',
      actions: [
        FilledButton.tonalIcon(
          onPressed: _loading || _working ? null : _openJobCard,
          icon: const Icon(Icons.description_outlined),
          label: const Text('Open Job Card'),
        ),
      ],
      child: _loading
          ? const AppLoadingState(label: 'Loading job card...')
          : ListView(
              children: [
                _RepairStageBar(currentIndex: _stageIndex),
                const SizedBox(height: 12),
                if (_isManager) _managerStageMessage(),
                if (_isManager) const SizedBox(height: 12),
                SectionCard(
                  title: 'Repair job',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line('Repair', _job.title),
                      _line('Defect / description', _job.description),
                      _line('Priority', _label(_job.priority)),
                      _line('Status', _label(_job.status)),
                      _line(
                        'Technician',
                        _job.technicianName.isEmpty
                            ? 'Unassigned'
                            : _job.technicianName,
                      ),
                      _line('Work notes', _job.workNotes),
                      _line('Parts notes', _job.partsNotes),
                      _line(
                        'Actual hours',
                        _job.actualHours.toStringAsFixed(1),
                      ),
                      _line(
                        'Actual cost',
                        '£${_job.actualCost.toStringAsFixed(2)}',
                      ),
                      _line('Roadworthy', _job.roadworthy ? 'Yes' : 'No'),
                      if (_job.signedOffName.isNotEmpty)
                        _line('Signed off by', _job.signedOffName),
                      if (_job.signedOffAt != null)
                        _line('Signed off', _date(_job.signedOffAt!)),
                    ],
                  ),
                ),
                if (inspection != null) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Source inspection',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _line('Inspection', inspection.inspectionNumber),
                        _line('Type', _label(inspection.inspectionType)),
                        _line('Started', _date(inspection.dateStarted)),
                        _line(
                          'Driver / inspector',
                          inspection.driverName?.trim().isNotEmpty == true
                              ? inspection.driverName!
                              : inspection.technicianName,
                        ),
                        _line(
                          'Inspection mileage',
                          inspection.mileage.toString(),
                        ),
                        _line(
                          'Technician mileage',
                          _job.technicianMileage?.toString() ?? 'Not recorded',
                        ),
                        _line('Inspection notes', inspection.notes),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SectionCard(
                  title: 'Defect evidence',
                  subtitle: _evidence.isEmpty
                      ? null
                      : '${_evidence.length} file(s) linked to this repair',
                  child: _evidence.isEmpty
                      ? const Text(
                          'No photos or evidence are linked to this defect.',
                        )
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final evidence in _evidence)
                              _evidenceCard(evidence),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                _workflowActions(canWork),
              ],
            ),
    );
  }

  Widget _managerStageMessage() {
    if (_job.status == 'completed') {
      return const SectionCard(
        variant: SectionCardVariant.compact,
        title: 'Manager sign-off complete',
        child: Text('This repair has been approved and closed.'),
      );
    }
    if (_job.status == 'awaitingInspection') {
      return const SectionCard(
        variant: SectionCardVariant.alert,
        title: 'Ready for Manager sign-off',
        child: Text(
          'The Technician has completed the repair. Review the work and either approve it or return it to the Technician.',
        ),
      );
    }
    return const SectionCard(
      variant: SectionCardVariant.compact,
      title: 'Manager sign-off',
      child: Text(
        'Waiting for the Technician to complete the repair and submit it for sign-off.',
      ),
    );
  }

  Widget _workflowActions(bool canWork) {
    final buttons = <Widget>[];
    if (_isManager &&
        _job.status != 'completed' &&
        _job.status != 'cancelled') {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _working ? null : _assignTechnician,
          icon: const Icon(Icons.engineering_outlined),
          label: const Text('Assign technician'),
        ),
      );
    }
    if (_isAssignedTechnician && _job.status == 'assigned') {
      buttons.add(
        FilledButton.icon(
          onPressed: _working ? null : _startRepair,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Repair'),
        ),
      );
    }
    if (canWork &&
        (_job.status == 'inProgress' || _job.status == 'awaitingParts')) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _working ? null : _editProgress,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Update Work'),
        ),
      );
    }
    if (_isAssignedTechnician && _job.status == 'inProgress') {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _working ? null : _markAwaitingParts,
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Waiting for Parts'),
        ),
      );
      buttons.add(
        FilledButton.icon(
          onPressed: _working ? null : _completeRepair,
          icon: const Icon(Icons.task_alt),
          label: const Text('Complete Repair'),
        ),
      );
    }
    if (_isAssignedTechnician && _job.status == 'awaitingParts') {
      buttons.add(
        FilledButton.icon(
          onPressed: _working ? null : _resumeRepair,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Resume Repair'),
        ),
      );
    }
    if (_isManager && _job.status == 'awaitingInspection') {
      buttons.add(
        OutlinedButton.icon(
          onPressed: _working ? null : _returnToTechnician,
          icon: const Icon(Icons.undo),
          label: const Text('Return to Technician'),
        ),
      );
      buttons.add(
        FilledButton.icon(
          onPressed: _working ? null : _signOff,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Approve & Sign Off'),
        ),
      );
    }
    return Wrap(spacing: 12, runSpacing: 12, children: buttons);
  }

  Widget _evidenceCard(BackendWorkshopEvidence evidence) {
    return SizedBox(
      width: 240,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _previewEvidence(evidence),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: evidence.contentType.toLowerCase().startsWith('image/')
                    ? FutureBuilder<String>(
                        future: widget.repository.createEvidenceSignedUrl(
                          evidence.storagePath,
                        ),
                        builder: (context, snapshot) {
                          final url = snapshot.data;
                          if (url == null) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.description_outlined, size: 44),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evidence.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (evidence.caption.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(evidence.caption, maxLines: 2),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _previewEvidence(BackendWorkshopEvidence evidence) async {
    try {
      final bytes = await widget.repository.downloadEvidence(
        evidence.storagePath,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => FleetIqDocumentViewer(
            title: evidence.caption.trim().isEmpty
                ? evidence.fileName
                : evidence.caption,
            fileName: evidence.fileName,
            contentType: evidence.contentType,
            bytes: bytes,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open evidence: $error')),
      );
    }
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 155,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(value.trim().isEmpty ? '—' : value)),
      ],
    ),
  );

  static String _label(String value) => value
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _RepairStageBar extends StatelessWidget {
  const _RepairStageBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const labels = ['Assigned', 'Repair', 'Manager sign-off', 'Completed'];
    return SectionCard(
      variant: SectionCardVariant.compact,
      title: 'Repair progress',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          return compact
              ? Column(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      _stage(context, labels[i], i),
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < labels.length; i++) ...[
                      Expanded(child: _stage(context, labels[i], i)),
                      if (i < labels.length - 1)
                        Icon(
                          Icons.chevron_right,
                          color: i < currentIndex
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                        ),
                    ],
                  ],
                );
        },
      ),
    );
  }

  Widget _stage(BuildContext context, String label, int index) {
    final complete = index < currentIndex;
    final current = index == currentIndex;
    final color = complete || current
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        complete ? Icons.check_circle : Icons.radio_button_checked,
        color: color,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: current ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
