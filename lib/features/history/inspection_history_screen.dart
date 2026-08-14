import 'package:flutter/material.dart';

import '../auth/services/permission_service.dart';

import '../../database/database_service.dart';
import '../../database/inspection_repository.dart';

import '../inspections/models/inspection.dart';
import '../inspections/models/inspection_item.dart';

import '../inspections/repositories/inspection_results_repository.dart';

import 'inspection_details_screen.dart';

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});

  @override
  State<InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState
    extends State<InspectionHistoryScreen> {
  late final InspectionRepository repository;

  late final InspectionResultsRepository
      resultsRepository;

  late Future<List<Inspection>> inspectionsFuture;

  @override
  void initState() {
    super.initState();

    repository = InspectionRepository(
      databaseService: DatabaseService(),
    );

    resultsRepository =
        InspectionResultsRepository(
      appDatabase: DatabaseService().database,
    );

    inspectionsFuture =
        repository.getInspections();
  }

  Future<void> refresh() async {
    setState(() {
      inspectionsFuture =
          repository.getInspections();
    });
  }

  Color resultColor(String result) {
    switch (result.toUpperCase()) {
      case 'PASS':
        return Colors.green;

      case 'FAIL':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  Future<List<InspectionItem>>
      failedItems(
    Inspection inspection,
  ) {
    return resultsRepository
        .getFailedItems(
      inspection.inspectionNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PermissionService.instance.isDriver) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('Drivers cannot access fleet inspection history.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Inspection History'),
      ),
      body: FutureBuilder<List<Inspection>>(
        future: inspectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final inspections =
              snapshot.data ?? [];

          if (inspections.isEmpty) {
            return const Center(
              child: Text(
                'No inspections found.',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: inspections.length,
              itemBuilder:
                  (context, index) {
                final inspection =
                    inspections[index];

                return FutureBuilder<
                    List<InspectionItem>>(
                  future:
                      failedItems(
                    inspection,
                  ),
                  builder:
                      (context, resultSnapshot) {
                    final failed =
                        resultSnapshot.data ??
                            [];

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 3,
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
                                Expanded(
                                  child: Text(
                                    inspection
                                        .inspectionNumber,
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: resultColor(
                                        inspection
                                            .overallResult),
                                    borderRadius:
                                        BorderRadius.circular(
                                            20),
                                  ),
                                  child: Text(
                                    inspection
                                        .overallResult,
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              'Vehicle: ${inspection.registration}',
                            ),

                            Text(
                              'Driver: ${inspection.driver}',
                            ),

                            Text(
                              'Status: ${inspection.status}',
                            ),                            const SizedBox(
                              height: 16,
                            ),

                            if (failed.isNotEmpty) ...[
                              const Text(
                                'Failed Items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              ...failed.map(
                                (item) => Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              item.title,
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                            if (item.notes
                                                .trim()
                                                .isNotEmpty)
                                              Text(
                                                item.notes,
                                                style:
                                                    const TextStyle(
                                                  color:
                                                      Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              const Text(
                                'No defects recorded.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],

                            const SizedBox(
                              height: 16,
                            ),

                            Align(
                              alignment:
                                  Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.visibility,
                                ),
                                label: const Text(
                                  'View Details',
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InspectionDetailsScreen(
                                        inspection:
                                            inspection,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
