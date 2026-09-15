import 'dart:async';

import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/backend_workshop_template.dart';
import '../../../backend/workshop/supabase_workshop_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import 'central_workshop_template_wizard_screen.dart';

class CentralWorkshopTemplatesScreen extends StatefulWidget {
  const CentralWorkshopTemplatesScreen({super.key});

  @override
  State<CentralWorkshopTemplatesScreen> createState() =>
      _CentralWorkshopTemplatesScreenState();
}

class _CentralWorkshopTemplatesScreenState
    extends State<CentralWorkshopTemplatesScreen> {
  final _repository = const BackendWorkshopRepository(
    SupabaseWorkshopGateway(),
  );
  late Future<List<BackendWorkshopTemplate>> _future;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _future = _repository.listTemplates();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _repository.listTemplates());
  }

  Future<void> _openWizard({BackendWorkshopTemplate? template}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CentralWorkshopTemplateWizardScreen(
          repository: _repository,
          template: template,
        ),
      ),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Inspection Templates',
    subtitle:
        'Build reusable central Workshop inspection forms with the wizard.',
    floatingActionButton:
        PermissionService.instance.canManageInspectionTemplates
        ? FloatingActionButton.extended(
            onPressed: _openWizard,
            icon: const Icon(Icons.add),
            label: const Text('Create Form'),
          )
        : null,
    child: FutureBuilder<List<BackendWorkshopTemplate>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppLoadingState(
            label: 'Loading inspection templates...',
          );
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return AppErrorState(
            title: 'Unable to load templates',
            message: '${snapshot.error}',
            onRetry: _refresh,
          );
        }
        final rows = snapshot.data ?? const <BackendWorkshopTemplate>[];
        if (rows.isEmpty) {
          return AppEmptyState(
            icon: Icons.article_outlined,
            title: 'No templates',
            message:
                'Create a custom inspection form using the step-by-step wizard.',
            action: PermissionService.instance.canManageInspectionTemplates
                ? FilledButton.icon(
                    onPressed: _openWizard,
                    icon: const Icon(Icons.add),
                    label: const Text('Create form'),
                  )
                : null,
          );
        }
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = rows[index];
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.fact_check_outlined),
              ),
              title: Text(row.name),
              subtitle: Text(
                row.description.isEmpty
                    ? (row.inspectionType ?? 'General')
                    : '${row.inspectionType ?? 'General'} · ${row.description}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (row.isActive) const Icon(Icons.check_circle_outline),
                  if (PermissionService.instance.canManageInspectionTemplates)
                    const Icon(Icons.chevron_right),
                ],
              ),
              onTap: PermissionService.instance.canManageInspectionTemplates
                  ? () => _openWizard(template: row)
                  : null,
            );
          },
        );
      },
    ),
  );
}
