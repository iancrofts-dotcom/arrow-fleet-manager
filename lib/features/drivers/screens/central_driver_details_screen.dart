import 'package:flutter/material.dart';

import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/central_password_service.dart';
import '../../auth/services/permission_service.dart';
import '../../documents/screens/central_document_list_screen.dart';
import '../models/central_driver_assignment.dart';
import '../models/driver.dart';
import '../services/central_driver_assignment_read_service.dart';
import 'central_driver_compliance_screen.dart';
import 'central_assign_vehicle_screen.dart';
import '../../../backend/drivers/backend_driver_assignment_repository.dart';
import '../../../backend/drivers/central_driver_management_repository.dart';
import '../../../backend/drivers/supabase_driver_management_gateway.dart';
import '../../../backend/drivers/central_driver_assignment_write_service.dart';
import '../../../backend/drivers/supabase_driver_assignment_gateway.dart';
import 'edit_driver_screen.dart';

class CentralDriverDetailsScreen extends StatefulWidget {
  const CentralDriverDetailsScreen({
    super.key,
    required this.driver,
    this.assignmentReadService,
  });

  final Driver driver;
  final CentralDriverAssignmentReadService? assignmentReadService;

  @override
  State<CentralDriverDetailsScreen> createState() =>
      _CentralDriverDetailsScreenState();
}

class _CentralDriverDetailsScreenState
    extends State<CentralDriverDetailsScreen> {
  late final CentralDriverAssignmentReadService _assignmentReadService;
  late Driver _driver;
  late Future<List<CentralDriverAssignment>> _assignmentsFuture;

  @override
  void initState() {
    super.initState();
    _driver = widget.driver;
    final identity = _driver.identity;
    if (identity?.centralIdOrNull == null || _driver.id != null) {
      throw ArgumentError('Central Driver details require UUID identity.');
    }
    _assignmentReadService =
        widget.assignmentReadService ??
        CentralDriverAssignmentReadService.forSupabase();
    _loadAssignments();
  }

  void _loadAssignments() {
    _assignmentsFuture = _assignmentReadService.getAssignmentsForDriver(
      _driver.identity!,
    );
  }

  Future<void> _refreshAssignments() async {
    setState(_loadAssignments);
    await _assignmentsFuture;
  }

  String get _centralDriverId => _driver.identity!.centralIdOrNull!;

  Future<void> _openCompliance() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralDriverComplianceScreen(
          driverId: _centralDriverId,
          driverName: _driver.fullName,
        ),
      ),
    );
  }

  Future<void> _openDocuments() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralDocumentListScreen(
          initialFilter: 'Driver',
          entityType: 'driver',
          entityId: _centralDriverId,
          ownerLabel: _driver.fullName,
        ),
      ),
    );
  }

  Future<void> _assignVehicle() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralAssignVehicleScreen(
          driverId: _centralDriverId,
          driverName: _driver.fullName,
        ),
      ),
    );
    if (changed == true && mounted) await _refreshAssignments();
  }

  Future<void> _endCurrentAssignment() async {
    final repository = BackendDriverAssignmentRepository(
      SupabaseDriverAssignmentGateway(),
    );
    final rows = await repository.listAssignmentsForDriver(_centralDriverId);
    final active = rows.where((row) => row.isActive).toList(growable: false);
    if (active.isEmpty || !mounted) return;
    final current = active.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Vehicle Assignment?'),
        content: const Text(
          'This ends the current assignment and keeps it in assignment history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('End Assignment'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CentralDriverAssignmentWriteService().end(current);
      if (mounted) await _refreshAssignments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to end assignment: $error')),
      );
    }
  }

  Future<void> _sendPasswordSetupLink() async {
    final email = _driver.email?.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This Driver does not have a login email address.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send password setup link?'),
        content: Text(
          'FleetIQ will send a secure password setup email to $email. The Driver will choose their own password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await const CentralPasswordService().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password setup link sent to $email.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to send the password setup link. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteDriver() async {
    if (!PermissionService.instance.isAdmin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Driver?'),
        content: Text(
          'Delete ${_driver.fullName} from active Driver Management?\n\n'
          'FleetIQ will remove the linked portal login and retain historical '
          'assignments, inspections, compliance and evidence for audit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Driver'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await const CentralDriverManagementRepository(
        SupabaseDriverManagementGateway(),
      ).deleteDriver(_driver.identity!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_driver.fullName} deleted. Historical records retained.',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete Driver.\n$error')),
      );
    }
  }

  Future<void> _editDriver() async {
    final updated = await Navigator.push<Driver>(
      context,
      MaterialPageRoute(builder: (_) => EditDriverScreen(driver: _driver)),
    );
    if (updated == null || !mounted) return;
    setState(() => _driver = updated);
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: _driver.fullName,
    subtitle: 'Driver profile, assignment and compliance records.',
    actions: [
      if (PermissionService.instance.canManageDrivers) ...[
        OutlinedButton.icon(
          onPressed: _openCompliance,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Compliance'),
        ),
        OutlinedButton.icon(
          onPressed: _openDocuments,
          icon: const Icon(Icons.folder_shared_outlined),
          label: const Text('Documents'),
        ),
        OutlinedButton.icon(
          onPressed: _driver.email?.trim().isNotEmpty == true
              ? _sendPasswordSetupLink
              : null,
          icon: const Icon(Icons.mark_email_read_outlined),
          label: const Text('Send Password Link'),
        ),
        OutlinedButton.icon(
          onPressed: _editDriver,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Driver'),
        ),
        if (PermissionService.instance.isAdmin)
          OutlinedButton.icon(
            onPressed: _deleteDriver,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Driver'),
          ),
      ],
    ],
    child: RefreshIndicator(
      onRefresh: _refreshAssignments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _profileSection(context),
          const SizedBox(height: 12),
          _assignmentSection(context),
          const SizedBox(height: 12),
          if (PermissionService.instance.canManageDrivers && _driver.isActive)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _assignVehicle,
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Assign / Change Vehicle'),
                ),
                OutlinedButton.icon(
                  onPressed: _endCurrentAssignment,
                  icon: const Icon(Icons.link_off_outlined),
                  label: const Text('End Current Assignment'),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Assignment history retained'),
              subtitle: const Text(
                'Reassignment closes the previous Driver/Vehicle relationship and preserves the historical record.',
              ),
              trailing: _driver.isActive
                  ? StatusBadge.success('Active')
                  : StatusBadge.neutral('Inactive'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _profileSection(BuildContext context) => SectionCard(
    title: 'Driver details',
    child: Column(
      children: [
        _tile(Icons.badge_outlined, 'Licence', _driver.licenceNumber),
        _tile(
          Icons.calendar_today_outlined,
          'Licence expiry',
          _driver.licenceExpiry == null
              ? 'Not set'
              : _formatDate(_driver.licenceExpiry!),
        ),
        _tile(Icons.phone_outlined, 'Phone', _driver.phone ?? 'Not provided'),
        _tile(Icons.email_outlined, 'Email', _driver.email ?? 'Not provided'),
      ],
    ),
  );

  Widget _assignmentSection(BuildContext context) => SectionCard(
    title: 'Vehicle assignments',
    subtitle: 'Current and previous central Vehicle assignments.',
    child: FutureBuilder<List<CentralDriverAssignment>>(
      future: _assignmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppLoadingState(label: 'Loading assignments...'),
          );
        }
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Unable to load assignments',
            message:
                'The Driver profile is available, but assignment data could not be loaded.',
            onRetry: _refreshAssignments,
          );
        }

        final assignments = snapshot.data ?? const <CentralDriverAssignment>[];
        if (assignments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: AppEmptyState(
              icon: Icons.link_off_outlined,
              title: 'No assignments',
              message:
                  'No central vehicle assignments are recorded for this Driver.',
            ),
          );
        }

        final current = assignments.where((row) => row.isCurrent).toList();
        final history = assignments.where((row) => !row.isCurrent).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (current.isNotEmpty) ...[
              Text('Current', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...current.map((row) => _assignmentTile(row, current: true)),
            ],
            if (history.isNotEmpty) ...[
              if (current.isNotEmpty) const SizedBox(height: 12),
              Text('History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...history.map(_assignmentTile),
            ],
          ],
        );
      },
    ),
  );

  Widget _assignmentTile(
    CentralDriverAssignment assignment, {
    bool current = false,
  }) => Card(
    child: ListTile(
      leading: Icon(
        current ? Icons.local_shipping_outlined : Icons.history_outlined,
      ),
      title: Text(assignment.vehicleLabel),
      subtitle: Text(
        '${assignment.vehicleDescription}\n${_assignmentPeriod(assignment)}',
      ),
      isThreeLine: true,
      trailing: current
          ? StatusBadge.success('Current')
          : StatusBadge.neutral('Ended'),
    ),
  );

  Widget _tile(IconData icon, String title, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(value),
  );

  String _assignmentPeriod(CentralDriverAssignment assignment) {
    final start = _formatDateTime(assignment.assignedFrom);
    final end = assignment.assignedTo == null
        ? 'Present'
        : _formatDateTime(assignment.assignedTo!);
    return '$start — $end';
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${_formatDate(local)} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
