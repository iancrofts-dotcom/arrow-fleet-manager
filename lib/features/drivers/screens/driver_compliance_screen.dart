import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../documents/screens/driver_compliance_documents_screen.dart';
import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

import '../models/driver_compliance.dart';
import '../services/driver_compliance_service.dart';

class DriverComplianceScreen extends StatefulWidget {
  const DriverComplianceScreen({super.key, required this.driverId});

  final int driverId;

  @override
  State<DriverComplianceScreen> createState() => _DriverComplianceScreenState();
}

class _DriverComplianceScreenState extends State<DriverComplianceScreen> {
  final DriverComplianceService _service = DriverComplianceService();

  final PermissionService _permissions = PermissionService.instance;

  bool _loading = true;
  bool _saving = false;

  DateTime? _licenceExpiry;
  DateTime? _cpcExpiry;
  DateTime? _medicalExpiry;
  DateTime? _dbsExpiry;
  DateTime? _taxiLicenceExpiry;

  @override
  void initState() {
    super.initState();
    _loadCompliance();
  }

  Future<void> _loadCompliance() async {
    final record = await _service.getByDriverId(widget.driverId);

    if (!mounted) return;

    if (record != null) {
      _licenceExpiry = record.licenceExpiry;
      _cpcExpiry = record.cpcExpiry;
      _medicalExpiry = record.medicalExpiry;
      _dbsExpiry = record.dbsExpiry;
      _taxiLicenceExpiry = record.taxiLicenceExpiry;
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _pickLicenceDate() async {
    if (!_permissions.canManageDrivers) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _licenceExpiry ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _licenceExpiry = picked;
    });
  }

  Future<void> _pickCpcDate() async {
    if (!_permissions.canManageDrivers) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _cpcExpiry ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _cpcExpiry = picked;
    });
  }

  Future<void> _pickMedicalDate() async {
    if (!_permissions.canManageDrivers) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _medicalExpiry ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _medicalExpiry = picked;
    });
  }

  Future<void> _pickDbsDate() async {
    if (!_permissions.canManageDrivers) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dbsExpiry ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _dbsExpiry = picked);
  }

  Future<void> _pickTaxiLicenceDate() async {
    if (!_permissions.canManageDrivers) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _taxiLicenceExpiry ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _taxiLicenceExpiry = picked);
  }

  Future<void> _save() async {
    if (!_permissions.canManageDrivers || _saving) {
      return;
    }

    final licenceExpiry = _licenceExpiry;
    final cpcExpiry = _cpcExpiry;
    final medicalExpiry = _medicalExpiry;
    if (licenceExpiry == null || cpcExpiry == null || medicalExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter Licence, CPC and Medical expiry dates before saving.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final compliance = DriverCompliance(
        driverId: widget.driverId,
        licenceExpiry: licenceExpiry,
        cpcExpiry: cpcExpiry,
        medicalExpiry: medicalExpiry,
        dbsExpiry: _dbsExpiry,
        taxiLicenceExpiry: _taxiLicenceExpiry,
        lastUpdated: DateTime.now(),
      );

      await _service.save(compliance);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save driver compliance.\n$error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissions.canViewDrivers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'You do not have permission to view driver compliance.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    if (_loading) {
      return const AppPageScaffold(
        title: 'Driver Compliance',
        subtitle: 'Licence, CPC, medical and DBS records.',
        child: AppLoadingState(label: 'Loading compliance records...'),
      );
    }

    return AppPageScaffold(
      title: 'Driver Compliance',
      subtitle: 'Licence, CPC, medical and DBS records.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _dateTile(
            title: 'Licence Expiry',
            date: _licenceExpiry,
            status: _service.status(_licenceExpiry),
            onTap: _pickLicenceDate,
          ),

          const SizedBox(height: 12),

          _dateTile(
            title: 'CPC Expiry',
            date: _cpcExpiry,
            status: _service.status(_cpcExpiry),
            onTap: _pickCpcDate,
          ),

          const SizedBox(height: 12),

          _dateTile(
            title: 'Medical Expiry',
            date: _medicalExpiry,
            status: _service.status(_medicalExpiry),
            onTap: _pickMedicalDate,
          ),

          const SizedBox(height: 12),

          _dateTile(
            title: 'DBS Expiry',
            date: _dbsExpiry,
            status: _service.status(_dbsExpiry),
            onTap: _pickDbsDate,
          ),

          const SizedBox(height: 12),
          _dateTile(
            title: 'Taxi Licence Expiry (optional)',
            date: _taxiLicenceExpiry,
            status: _service.status(_taxiLicenceExpiry),
            onTap: _pickTaxiLicenceDate,
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DriverComplianceDocumentsScreen(
                    driverId: widget.driverId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.folder_shared_outlined),
            label: const Text('Compliance Evidence'),
          ),

          const SizedBox(height: 32),

          if (_permissions.canManageDrivers)
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Compliance'),
            ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime? date,
    required String status,
    required VoidCallback onTap,
  }) {
    final color = _statusColor(status);

    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.verified_user, color: color),
        title: Text(title),
        subtitle: Text(date == null ? 'Not recorded' : _formatDate(date)),
        trailing: _statusBadge(status),
        onTap: _permissions.canManageDrivers ? onTap : null,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Expired':
        return Colors.red;

      case 'Due Soon':
        return Colors.orange;

      case 'Not Recorded':
        return Colors.grey;

      default:
        return Colors.green;
    }
  }

  StatusBadge _statusBadge(String status) {
    switch (status) {
      case 'Expired':
        return StatusBadge.error('Expired');
      case 'Due Soon':
        return StatusBadge.warning('Due Soon');
      case 'Not Recorded':
        return StatusBadge.neutral('Not Recorded');
      default:
        return StatusBadge.success('Valid');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
