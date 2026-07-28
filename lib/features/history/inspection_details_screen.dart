import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/database_service.dart';
import '../inspections/models/inspection.dart';
import '../inspections/models/inspection_item.dart';
import '../inspections/repositories/inspection_results_repository.dart';
import '../repairs/models/repair.dart';
import '../repairs/repositories/repair_repository.dart';

class InspectionDetailsScreen extends StatefulWidget {
  final Inspection inspection;

  const InspectionDetailsScreen({
    super.key,
    required this.inspection,
  });

  @override
  State<InspectionDetailsScreen> createState() =>
      _InspectionDetailsScreenState();
}

class _InspectionDetailsScreenState
    extends State<InspectionDetailsScreen> {
  late final InspectionResultsRepository
      _resultsRepository;

  late final RepairRepository
      _repairRepository;

  late Future<List<InspectionItem>>
      _failedItemsFuture;

  @override
  void initState() {
    super.initState();

    _resultsRepository =
        InspectionResultsRepository(
      appDatabase: DatabaseService().database,
    );

    _repairRepository = RepairRepository();

    _failedItemsFuture =
        _resultsRepository.getFailedItems(
      widget.inspection.inspectionNumber,
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String title,
    required String value,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 12,
              ),
              child: Icon(
                icon,
                size: 22,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _statusColour() {
    switch (widget.inspection.overallResult) {
      case 'Pass':
        return Colors.green;

      case 'Fail':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  Future<void> _createRepair(
    InspectionItem item,
  ) async {
    final repair = Repair(
      repairNumber:
          'R-${DateTime.now().millisecondsSinceEpoch}',
      inspectionNumber:
          widget.inspection.inspectionNumber,
      registration:
          widget.inspection.registration,
      driver: widget.inspection.driver,
      defect: item.title,
      defectNotes: item.notes,
      photoPath: item.photoPath,
      mechanic: 'Unassigned',
      priority: 'Medium',
      status: 'Awaiting Repair',
      dateRaised: DateTime.now(),
      dueDate: null,
      completedDate: null,
      repairNotes: '',
    );

    await _repairRepository.saveRepair(
      repair,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Repair created successfully.',
        ),
      ),
    );
  }

  String get formattedDate =>
      DateFormat(
        'dd MMM yyyy HH:mm',
      ).format(
        widget.inspection.inspectionDate,
      );

  @override
  Widget build(BuildContext context) {
    final inspection =
        widget.inspection;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inspection ${inspection.inspectionNumber}',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Inspection Summary',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),

                const SizedBox(height: 20),

                _detailRow(
                  context,
                  title: 'Inspection No.',
                  value:
                      inspection.inspectionNumber,
                  icon: Icons.tag,
                ),

                _detailRow(
                  context,
                  title: 'Driver',
                  value: inspection.driver,
                  icon: Icons.person,
                ),

                _detailRow(
                  context,
                  title: 'Vehicle',
                  value:
                      inspection.registration,
                  icon:
                      Icons.local_shipping,
                ),

                _detailRow(
                  context,
                  title: 'Inspection Date',
                  value: formattedDate,
                  icon:
                      Icons.calendar_today,
                ),

                _detailRow(
                  context,
                  title: 'Mileage',
                  value:
                      '${inspection.mileage}',
                  icon: Icons.speed,
                ),

                _detailRow(
                  context,
                  title: 'Fuel Level',
                  value:
                      inspection.fuelLevel,
                  icon:
                      Icons.local_gas_station,
                ),                const SizedBox(height: 20),

                Row(
                  children: [
                    const Text(
                      'Overall Result',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      backgroundColor: _statusColour(),
                      label: Text(
                        inspection.overallResult,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      label: Text(
                        inspection.status,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 40),

                Text(
                  'Comments',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    inspection.comments.isEmpty
                        ? 'No comments recorded.'
                        : inspection.comments,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'Failed Items',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),

                const SizedBox(height: 12),

                FutureBuilder<List<InspectionItem>>(
                  future: _failedItemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            snapshot.error.toString(),
                          ),
                        ),
                      );
                    }

                    final failed =
                        snapshot.data ?? [];

                    if (failed.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No defects were recorded during this inspection.',
                              textAlign:
                                  TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: failed.map((item) {
                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style:
                                            const TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (item.notes
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  Text(item.notes),
                                ],

                                if (item.photoPath !=
                                    null) ...[
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context:
                                            context,
                                        builder:
                                            (_) =>
                                                Dialog(
                                          child:
                                              InteractiveViewer(
                                            child:
                                                Image.file(
                                              File(
                                                item.photoPath!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                        8,
                                      ),
                                      child: Image.file(
                                        File(
                                          item.photoPath!,
                                        ),
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(
                                  height: 16,
                                ),

                                SizedBox(
                                  width: double.infinity,
                                  child:
                                      ElevatedButton.icon(
                                    onPressed: () =>
                                        _createRepair(
                                      item,
                                    ),
                                    icon: const Icon(
                                      Icons.build,
                                    ),
                                    label: const Text(
                                      'Create Repair',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                    label: const Text(
                      'Back to History',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}