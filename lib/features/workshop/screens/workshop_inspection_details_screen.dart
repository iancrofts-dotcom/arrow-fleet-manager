import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/inspection_item.dart';
import '../models/inspection_photo.dart';
import '../models/workshop_inspection.dart';
import '../repositories/inspection_photo_repository.dart';
import '../repositories/workshop_repository.dart';

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

    return _InspectionDetailsData(
      inspection: inspection,
      items: items,
      photos: photos,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workshop Inspection',
        ),
      ),
      body: FutureBuilder<_InspectionDetailsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final details = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(
                  context,
                  details.inspection,
                ),
                const SizedBox(height: 16),
                _buildVehicleCard(
                  context,
                  details.inspection,
                ),
                const SizedBox(height: 16),
                _buildSignOffCard(
                  context,
                  details.inspection,
                ),
                const SizedBox(height: 16),
                _buildResultCard(
                  context,
                  details.inspection,
                ),
                const SizedBox(height: 16),
                _buildChecklistCard(
                  context,
                  details.items,
                  details.photos,
                ),
                if (details.inspection.notes
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(
                    context,
                    details.inspection.notes,
                  ),
                ],
              ],
            ),
          );
        },
      ),
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
          inspection.inspectionType.name,
        ),
      ],
    );
  }

  Widget _buildSignOffCard(
    BuildContext context,
    WorkshopInspection inspection,
  ) {
    return _sectionCard(
      context,
      title: 'Sign-Off',
      icon: Icons.people_outline,
      children: [
        _detailRow(
          'Technician',
          inspection.technicianName,
        ),
        _detailRow(
          'Workshop Manager',
          inspection.workshopManager ?? 'Not recorded',
        ),
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
            color: Theme.of(context)
                .dividerColor,
          ),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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

  const _InspectionDetailsData({
    required this.inspection,
    required this.items,
    required this.photos,
  });
}
