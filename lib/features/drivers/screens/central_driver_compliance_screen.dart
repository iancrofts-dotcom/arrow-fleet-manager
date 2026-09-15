import 'package:flutter/material.dart';

import '../../../backend/drivers/backend_driver_compliance.dart';
import '../../../backend/drivers/central_driver_compliance_repository.dart';
import '../../../backend/drivers/supabase_driver_compliance_gateway.dart';
import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';

class CentralDriverComplianceScreen extends StatefulWidget {
  const CentralDriverComplianceScreen({
    super.key,
    required this.driverId,
    this.driverName,
    this.repository,
  });

  final String driverId;
  final String? driverName;
  final CentralDriverComplianceRepository? repository;

  @override
  State<CentralDriverComplianceScreen> createState() =>
      _CentralDriverComplianceScreenState();
}

class _CentralDriverComplianceScreenState
    extends State<CentralDriverComplianceScreen> {
  late final CentralDriverComplianceRepository _repository;
  final _taxiLicenceNumber = TextEditingController();
  late Future<BackendDriverCompliance?> _future;
  DateTime? _licenceExpiry;
  DateTime? _cpcExpiry;
  DateTime? _medicalExpiry;
  DateTime? _dbsExpiry;
  DateTime? _taxiLicenceExpiry;
  bool _loadedIntoForm = false;
  bool _saving = false;

  bool get _canEdit {
    final permissions = PermissionService.instance;
    final ownDriverId = AuthService.instance.currentBackendDriverId;
    return permissions.canManageDrivers ||
        (permissions.isDriver && ownDriverId == widget.driverId);
  }

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        const CentralDriverComplianceRepository(
          SupabaseDriverComplianceGateway(),
        );
    _future = _repository.getCompliance(widget.driverId);
  }

  @override
  void dispose() {
    _taxiLicenceNumber.dispose();
    super.dispose();
  }

  void _prime(BackendDriverCompliance? value) {
    if (_loadedIntoForm) return;
    _loadedIntoForm = true;
    _licenceExpiry = value?.licenceExpiry;
    _cpcExpiry = value?.cpcExpiry;
    _medicalExpiry = value?.medicalExpiry;
    _dbsExpiry = value?.dbsExpiry;
    _taxiLicenceExpiry = value?.taxiLicenceExpiry;
    _taxiLicenceNumber.text = value?.taxiLicenceNumber ?? '';
  }

  Future<void> _pick(DateTime? current, ValueChanged<DateTime> save) async {
    if (!_canEdit) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2150),
    );
    if (picked != null && mounted) setState(() => save(picked));
  }

  Future<void> _save() async {
    if (!_canEdit || _saving) return;
    setState(() => _saving = true);
    try {
      final saved = await _repository.saveCompliance(
        driverId: widget.driverId,
        licenceExpiry: _licenceExpiry,
        cpcExpiry: _cpcExpiry,
        medicalExpiry: _medicalExpiry,
        dbsExpiry: _dbsExpiry,
        taxiLicenceNumber: _taxiLicenceNumber.text.trim().isEmpty
            ? null
            : _taxiLicenceNumber.text.trim(),
        taxiLicenceExpiry: _taxiLicenceExpiry,
      );
      if (!mounted) return;
      _loadedIntoForm = false;
      setState(() {
        _future = Future.value(saved);
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver compliance updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update compliance.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Driver Compliance',
    subtitle: widget.driverName == null
        ? 'Your central compliance record.'
        : '${widget.driverName} • Central compliance record.',
    child: FutureBuilder<BackendDriverCompliance?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading driver compliance...');
        }
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Unable to load compliance',
            message: '${snapshot.error}',
            onRetry: () => setState(
              () => _future = _repository.getCompliance(widget.driverId),
            ),
          );
        }
        _prime(snapshot.data);
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            SectionCard(
              title: 'Licence & professional compliance',
              child: Column(
                children: [
                  _dateTile(
                    'Driving Licence Expiry',
                    _licenceExpiry,
                    (date) => _licenceExpiry = date,
                  ),
                  _dateTile(
                    'CPC Expiry',
                    _cpcExpiry,
                    (date) => _cpcExpiry = date,
                  ),
                  _dateTile(
                    'Medical Expiry',
                    _medicalExpiry,
                    (date) => _medicalExpiry = date,
                  ),
                  _dateTile(
                    'DBS Expiry',
                    _dbsExpiry,
                    (date) => _dbsExpiry = date,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Taxi / Private Hire Licence',
              subtitle:
                  'Optional. Complete this for licensed taxi/private-hire drivers.',
              child: Column(
                children: [
                  TextField(
                    controller: _taxiLicenceNumber,
                    enabled: _canEdit,
                    decoration: const InputDecoration(
                      labelText: 'Taxi / Private Hire Licence Number',
                      prefixIcon: Icon(Icons.local_taxi_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _dateTile(
                    'Taxi / Private Hire Licence Expiry',
                    _taxiLicenceExpiry,
                    (date) => _taxiLicenceExpiry = date,
                  ),
                ],
              ),
            ),
            if (_canEdit) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save Compliance'),
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget _dateTile(String title, DateTime? value, ValueChanged<DateTime> save) {
    final status = _status(value);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(title),
      subtitle: Text(value == null ? 'Not recorded' : _formatDate(value)),
      trailing: switch (status) {
        'Expired' => StatusBadge.critical(status),
        'Due Soon' => StatusBadge.warning(status),
        'Current' => StatusBadge.success(status),
        _ => StatusBadge.neutral(status),
      },
      onTap: _canEdit ? () => _pick(value, save) : null,
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _status(DateTime? expiry) {
  if (expiry == null) return 'Not Recorded';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(expiry.year, expiry.month, expiry.day);
  if (day.isBefore(today)) return 'Expired';
  if (day.difference(today).inDays <= 30) return 'Due Soon';
  return 'Current';
}
