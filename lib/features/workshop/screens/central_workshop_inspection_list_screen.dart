import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_inspection.dart';
import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/supabase_workshop_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import 'central_workshop_inspection_details_screen.dart';

class CentralWorkshopInspectionListScreen extends StatefulWidget {
  const CentralWorkshopInspectionListScreen({super.key});
  @override
  State<CentralWorkshopInspectionListScreen> createState() =>
      _CentralWorkshopInspectionListScreenState();
}

class _CentralWorkshopInspectionListScreenState
    extends State<CentralWorkshopInspectionListScreen> {
  final _repository = const BackendWorkshopRepository(
    SupabaseWorkshopGateway(),
  );
  late Future<List<BackendWorkshopInspection>> _future = _repository
      .listInspections();

  Future<void> _refresh() async {
    setState(() => _future = _repository.listInspections());
    await _future;
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Workshop Inspections',
    subtitle: 'View and manage saved central inspections.',
    child: FutureBuilder<List<BackendWorkshopInspection>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading inspections...');
        }
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Unable to load inspections',
            message: '${snapshot.error}',
            onRetry: _refresh,
          );
        }
        final rows = snapshot.data ?? const <BackendWorkshopInspection>[];
        if (rows.isEmpty) {
          return const AppEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No inspections',
            message: 'No central Workshop inspections have been recorded.',
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.assignment_outlined),
                ),
                title: Text('${row.inspectionNumber} · ${row.registration}'),
                subtitle: Text(
                  '${row.inspectionType} · ${_label(row.status)} · ${_date(row.dateStarted)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CentralWorkshopInspectionDetailsScreen(
                        inspectionId: row.id,
                        repository: _repository,
                      ),
                    ),
                  );
                  if (mounted) {
                    await _refresh();
                  }
                },
              );
            },
          ),
        );
      },
    ),
  );

  static String _label(String value) => value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
  static String _date(DateTime value) {
    final d = value.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
