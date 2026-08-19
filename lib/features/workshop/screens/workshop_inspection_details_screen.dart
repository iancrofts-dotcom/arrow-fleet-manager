import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';

import '../models/inspection_item.dart';
import '../models/inspection_photo.dart';
import '../models/repair_job.dart';
import '../models/workshop_inspection.dart';
import '../repositories/inspection_photo_repository.dart';
import '../repositories/workshop_repository.dart';
import 'repair_jobs_screen.dart';

class WorkshopInspectionDetailsScreen
    extends StatefulWidget {
  final int inspectionId;

  const WorkshopInspectionDetailsScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  State<WorkshopInspectionDetailsScreen> createState() =>
      _WorkshopInspectionDetailsScreenState();
}

class _WorkshopInspectionDetailsScreenState
    extends State<WorkshopInspectionDetailsScreen> {
  final WorkshopRepository _repository =
      WorkshopRepository();

  final InspectionPhotoRepository _photoRepository =
      InspectionPhotoRepository();

  late Future<_InspectionDetailsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InspectionDetailsData> _load() async {
    final inspection =
        await _repository.getInspection(
      widget.inspectionId,
    );

    if (inspection == null) {
      throw Exception(
        'Inspection ${widget.inspectionId} could not be found.',
      );
    }

    final items =
        await _repository.getInspectionItems(
      widget.inspectionId,
    );

    final photos =
        await _photoRepository.getForInspection(
      widget.inspectionId,
    );

    final repairJobs =
        await _repository.getRepairJobs(
      widget.inspectionId,
    );

    final repairStatus =
        await _repository.getRepairCompletionStatus(
      widget.inspectionId,
    );

    return _InspectionDetailsData(
      inspection: inspection,
      items: items,
      photos: photos,
      repairJobs: repairJobs,
      repairStatus: repairStatus,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Color _resultColor(
    InspectionResult result,
  ) {
    switch (result) {
      case InspectionResult.pass:
        return Colors.green;
      case InspectionResult.fail:
        return Colors.red;
      case InspectionResult.advisory:
        return Colors.orange;
      case InspectionResult.pending:
        return Colors.grey;
    }
  }

  String _resultText(
    InspectionResult result,
  ) {
    switch (result) {
      case InspectionResult.pass:
        return 'PASS';
      case InspectionResult.fail:
        return 'FAIL';
      case InspectionResult.advisory:
        return 'ADVISORY';
      case InspectionResult.pending:
        return 'PENDING';
    }
  }

  Color _itemColor(
    InspectionItemStatus status,
  ) {
    switch (status) {
      case InspectionItemStatus.pass:
        return Colors.green;
      case InspectionItemStatus.fail:
        return Colors.red;
      case InspectionItemStatus.advisory:
        return Colors.orange;
      case InspectionItemStatus.notApplicable:
        return Colors.grey;
    }
  }

  String _itemStatusText(
    InspectionItemStatus status,
  ) {
    switch (status) {
      case InspectionItemStatus.pass:
        return 'PASS';
      case InspectionItemStatus.fail:
        return 'FAIL';
      case InspectionItemStatus.advisory:
        return 'ADVISORY';
      case InspectionItemStatus.notApplicable:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageWorkshop) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to view Workshop inspection details.',
          ),
        ),
      );
    }

    return FutureBuilder<_InspectionDetailsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppPageScaffold(
            title: 'Inspection Details',
            child: AppLoadingState(label: 'Loading inspection details...'),
          );
        }

        if (snapshot.hasError) {
          return AppPageScaffold(
            title: 'Inspection Details',
            child: AppErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            ),
          );
        }

        final details = snapshot.data!;
        final inspection = details.inspection;

        return AppPageScaffold(
          title: 'Inspection Details',
          subtitle:
              '${inspection.inspectionNumber} • ${inspection.registration}',
          actions: [
            IconButton(
              tooltip: 'Refresh inspection',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildHeader(context, inspection),
                const SizedBox(height: 16),
                _buildVehicleCard(context, inspection),
                const SizedBox(height: 16),
                _buildSignOffCard(context, inspection, details.repairStatus),
                const SizedBox(height: 16),
                _buildResultCard(context, inspection),
                const SizedBox(height: 16),
                _buildChecklistCard(context, details.items, details.photos),
                const SizedBox(height: 16),
                _buildRepairsCard(
                  context,
                  details.repairJobs,
                  details.repairStatus,
                ),
                if (inspection.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(context, inspection.notes),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WorkshopInspection inspection,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inspection ${inspection.inspectionNumber}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'dd MMM yyyy HH:mm',
                    ).format(
                      inspection.dateCompleted ??
                          inspection.dateStarted,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(
                _resultText(
                  inspection.overallResult,
                ),
              ),
              backgroundColor:
                  _resultColor(
                inspection.overallResult,
              ).withValues(alpha: 0.15),
              side: BorderSide(
                color: _resultColor(
                  inspection.overallResult,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    WorkshopInspection inspection,
  ) {
    return _sectionCard(
      context,
      title: 'Vehicle',
      icon: Icons.local_shipping_outlined,
      children: [
        _detailRow(
          'Registration',
          inspection.registration,
        ),
        _detailRow(
          'Fleet Number',
          inspection.fleetNumber,
        ),
        _detailRow(
          'Mileage',
          '${inspection.mileage}',
        ),
        _detailRow(
          'Inspection Type',
          _inspectionTypeLabel(inspection.inspectionType),
        ),
        if (inspection.templateName != null &&
            inspection.templateName!.trim().isNotEmpty)
          _detailRow('Inspection Template', inspection.templateName!),
      ],
    );
  }

  bool get _canSignOff {
    return PermissionService.instance.canSignOffInspection;
  }

  String _inspectionTypeLabel(WorkshopInspectionType type) {
    if (type == WorkshopInspectionType.driverDailyInspection) {
      return 'Driver Daily Inspection';
    }

    return type.name;
  }

  bool _hasManagerSignOff(
    WorkshopInspection inspection,
  ) {
    return inspection.status ==
            WorkshopInspectionStatus.signedOff ||
        (inspection.managerSignature != null &&
            inspection.managerSignature!.trim().isNotEmpty);
  }

  Future<void> _signOffInspection(
    WorkshopInspection inspection,
  ) async {
    if (!_canSignOff) {
      return;
    }

    if (inspection.status !=
        WorkshopInspectionStatus.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This inspection can only be signed off after it has been completed.',
          ),
        ),
      );
      return;
    }

    if (_hasManagerSignOff(inspection)) {
      return;
    }

    final repairStatus = await _repository.getRepairCompletionStatus(
      inspection.id!,
    );

    if (!mounted) return;

    if (repairStatus == RepairCompletionStatus.outstanding) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Complete or cancel all repair jobs before signing off this inspection.',
          ),
        ),
      );
      return;
    }

    final currentUser =
        AuthService.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in to sign off an inspection.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Off Inspection'),
          content: Text(
            'Are you sure you want to sign off inspection '
            '${inspection.inspectionNumber}?\\n\\n'
            'This will mark the inspection as signed off by '
            '${currentUser.username}.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Sign Off'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final updatedInspection = inspection.copyWith(
        status: WorkshopInspectionStatus.signedOff,
        managerSignature: currentUser.username,
        updatedAt: DateTime.now(),
      );

      final updatedRows =
          await _repository.updateInspection(
        updatedInspection,
      );

      if (!mounted) {
        return;
      }

      if (updatedRows == 0) {
        throw Exception(
          'The inspection could not be updated.',
        );
      }

      await _refresh();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inspection signed off by ${currentUser.username}.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to sign off inspection: $e',
          ),
        ),
      );
    }
  }

  Widget _buildSignOffCard(
    BuildContext context,
    WorkshopInspection inspection,
    RepairCompletionStatus repairStatus,
  ) {
    final signedOff = _hasManagerSignOff(inspection);
    final driverName = inspection.driverName;

    return _sectionCard(
      context,
      title: 'Sign-Off',
      icon: Icons.people_outline,
      children: [
        _detailRow(
          'Technician',
          inspection.technicianName,
        ),
        if (driverName != null && driverName.trim().isNotEmpty)
          _detailRow(
            'Driver',
            driverName,
          ),
        _detailRow(
          'Workshop Manager',
          inspection.workshopManager ?? 'Not recorded',
        ),
        if (signedOff) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Signed off by ${inspection.managerSignature ?? inspection.workshopManager ?? 'Manager'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (inspection.status ==
            WorkshopInspectionStatus.completed) ...[
          const SizedBox(height: 12),
          if (repairStatus == RepairCompletionStatus.outstanding)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sign-off is blocked until all repair jobs are completed or cancelled.',
                    ),
                  ),
                ],
              ),
            )
          else if (_canSignOff)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _signOffInspection(inspection),
                icon: const Icon(
                  Icons.verified_outlined,
                ),
                label: const Text('Sign Off Inspection'),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sign-off is restricted to an Administrator, Fleet Manager or Workshop Manager.',
                    ),
                  ),
                ],
              ),
            ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            'Sign-off becomes available when the inspection is completed.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    WorkshopInspection inspection,
  ) {
    return _sectionCard(
      context,
      title: 'Inspection Summary',
      icon: Icons.assessment_outlined,
      children: [
        _detailRow(
          'Vehicle Status',
          inspection.vehicleStatus.name,
        ),
        _detailRow(
          'Overall Result',
          _resultText(
            inspection.overallResult,
          ),
        ),
        _detailRow(
          'Inspection Score',
          '${inspection.inspectionScore}',
        ),
        _detailRow(
          'Critical Failures',
          '${inspection.criticalFailures}',
        ),
        _detailRow(
          'Advisories',
          '${inspection.advisories}',
        ),
        _detailRow(
          'Repairs Required',
          '${inspection.repairsRequired}',
        ),
        _detailRow(
          'Labour Hours',
          inspection.labourHours.toStringAsFixed(2),
        ),
        _detailRow(
          'Total Cost',
          '£${inspection.totalCost.toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildChecklistCard(
    BuildContext context,
    List<InspectionItem> items,
    List<InspectionPhoto> photos,
  ) {
    return _sectionCard(
      context,
      title: 'Checklist',
      icon: Icons.checklist_outlined,
      children: [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12,
            ),
            child: Text(
              'No checklist items were saved.',
            ),
          )
        else
          ...items.map(
            (item) => _buildChecklistItem(
              context,
              item,
              photos,
            ),
          ),
      ],
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    InspectionItem item,
    List<InspectionPhoto> photos,
  ) {
    final itemPhotos = photos.where(
      (photo) =>
          photo.inspectionItemId == item.id,
    ).toList();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  item.status ==
                          InspectionItemStatus.fail
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  color: _itemColor(item.status),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    _itemStatusText(item.status),
                  ),
                ),
              ],
            ),
            if (item.sectionTitle != null &&
                item.sectionTitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.sectionTitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (item.responseValue != null &&
                item.responseValue!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Response: ${item.responseValue}'),
            ],
            if (item.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(item.notes),
            ],
            if (item.repairRequired) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.build_outlined,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Repair required',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (itemPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: itemPhotos.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final photo =
                        itemPhotos[index];

                    return _buildPhoto(
                      context,
                      photo.filePath,
                    );
                  },
                ),
              ),
            ] else if (item.photoCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${item.photoCount} photo(s) recorded',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(
    BuildContext context,
    String path,
  ) {
    final file = File(path);

    if (!file.existsSync()) {
      return Container(
        width: 90,
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
        ),
      );
    }

    return InkWell(
      onTap: () => _showPhotoViewer(
        context,
        file,
      ),
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<void> _showPhotoViewer(
    BuildContext context,
    File file,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(
                        file,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepairsCard(
    BuildContext context,
    List<RepairJob> repairJobs,
    RepairCompletionStatus repairStatus,
  ) {
    final totalHours = repairJobs.fold<double>(
      0,
      (sum, job) => sum + job.estimatedHours,
    );

    final totalCost = repairJobs.fold<double>(
      0,
      (sum, job) => sum + job.estimatedCost,
    );

    return _sectionCard(
      context,
      title: 'Repairs',
      icon: Icons.build_outlined,
      children: [
        _buildRepairStatusRow(
          context,
          repairStatus,
        ),
        const SizedBox(height: 12),
        if (repairJobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No repair jobs were saved for this inspection.',
            ),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  context,
                  label: 'Jobs',
                  value: '${repairJobs.length}',
                  icon: Icons.build,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryTile(
                  context,
                  label: 'Hours',
                  value: totalHours.toStringAsFixed(1),
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryTile(
                  context,
                  label: 'Estimated',
                  value: '£${totalCost.toStringAsFixed(2)}',
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...repairJobs.map(
            (job) => _buildRepairJob(
              context,
              job,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RepairJobsScreen(
                      inspectionId: widget.inspectionId,
                    ),
                  ),
                );

                if (mounted) {
                  await _refresh();
                }
              },
              icon: const Icon(Icons.build_outlined),
              label: const Text('Open Repair Jobs'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepairStatusRow(
    BuildContext context,
    RepairCompletionStatus status,
  ) {
    String text;
    IconData icon;
    Color color;

    switch (status) {
      case RepairCompletionStatus.noRepairs:
        text = 'NO REPAIRS REQUIRED';
        icon = Icons.check_circle_outline;
        color = Colors.green;
      case RepairCompletionStatus.outstanding:
        text = 'REPAIRS OUTSTANDING';
        icon = Icons.warning_amber_outlined;
        color = Colors.orange;
      case RepairCompletionStatus.complete:
        text = 'REPAIRS COMPLETE';
        icon = Icons.task_alt;
        color = Colors.green;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.10),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairJob(
    BuildContext context,
    RepairJob job,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.build),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Chip(
                  label: Text(job.status.name),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(job.description),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.priority_high,
                    size: 18,
                  ),
                  label: Text(job.priority.name),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.schedule,
                    size: 18,
                  ),
                  label: Text(
                    '${job.estimatedHours.toStringAsFixed(1)} hrs',
                  ),
                ),
                Chip(
                  avatar: const Icon(
                    Icons.payments_outlined,
                    size: 18,
                  ),
                  label: Text(
                    '£${job.estimatedCost.toStringAsFixed(2)}',
                  ),
                ),
                if (job.partsRequired)
                  const Chip(
                    avatar: Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                    ),
                    label: Text('Parts required'),
                  ),
              ],
            ),
            if (job.technicianName.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Technician: ${job.technicianName}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(
    BuildContext context,
    String notes,
  ) {
    return _sectionCard(
      context,
      title: 'Final Notes',
      icon: Icons.notes_outlined,
      children: [
        Text(notes),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _InspectionDetailsData {
  final WorkshopInspection inspection;
  final List<InspectionItem> items;
  final List<InspectionPhoto> photos;
  final List<RepairJob> repairJobs;
  final RepairCompletionStatus repairStatus;

  const _InspectionDetailsData({
    required this.inspection,
    required this.items,
    required this.photos,
    required this.repairJobs,
    required this.repairStatus,
  });
}
