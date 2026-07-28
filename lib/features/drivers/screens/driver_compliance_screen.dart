import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';

import '../models/driver_compliance.dart';
import '../services/driver_compliance_service.dart';

class DriverComplianceScreen extends StatefulWidget {
  const DriverComplianceScreen({
    super.key,
    required this.driverId,
  });

  final int driverId;

  @override
  State<DriverComplianceScreen> createState() =>
      _DriverComplianceScreenState();
}

class _DriverComplianceScreenState
    extends State<DriverComplianceScreen> {

  final DriverComplianceService _service =
      DriverComplianceService();

  final PermissionService _permissions =
      PermissionService.instance;

  bool _loading = true;
  bool _saving = false;

  late DateTime _licenceExpiry;
  late DateTime _cpcExpiry;
  late DateTime _medicalExpiry;

  @override
  void initState() {
    super.initState();
    _loadCompliance();
  }

  Future<void> _loadCompliance() async {
    final record =
        await _service.getByDriverId(
      widget.driverId,
    );

    if (!mounted) return;

    if (record != null) {
      _licenceExpiry = record.licenceExpiry;
      _cpcExpiry = record.cpcExpiry;
      _medicalExpiry = record.medicalExpiry;
    } else {
      final now = DateTime.now();

      _licenceExpiry =
          DateTime(now.year + 1, now.month, now.day);

      _cpcExpiry =
          DateTime(now.year + 1, now.month, now.day);

      _medicalExpiry =
          DateTime(now.year + 1, now.month, now.day);
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
      initialDate: _licenceExpiry,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

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
      initialDate: _cpcExpiry,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

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
      initialDate: _medicalExpiry,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _medicalExpiry = picked;
    });
  }

  Future<void> _save() async {

    if (!_permissions.canManageDrivers) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final compliance = DriverCompliance(
      driverId: widget.driverId,
      licenceExpiry: _licenceExpiry,
      cpcExpiry: _cpcExpiry,
      medicalExpiry: _medicalExpiry,
      lastUpdated: DateTime.now(),
    );

    await _service.save(compliance);

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {

    if (!_permissions.canViewDrivers) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Compliance',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [          _dateTile(
            title: 'Licence Expiry',
            date: _licenceExpiry,
            status: _service.status(
              _licenceExpiry,
            ),
            onTap: _pickLicenceDate,
          ),

          const SizedBox(height: 12),

          _dateTile(
            title: 'CPC Expiry',
            date: _cpcExpiry,
            status: _service.status(
              _cpcExpiry,
            ),
            onTap: _pickCpcDate,
          ),

          const SizedBox(height: 12),

          _dateTile(
            title: 'Medical Expiry',
            date: _medicalExpiry,
            status: _service.status(
              _medicalExpiry,
            ),
            onTap: _pickMedicalDate,
          ),

          const SizedBox(height: 32),

          if (_permissions.canManageDrivers)
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.save,
                    ),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Save Compliance',
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime date,
    required String status,
    required VoidCallback onTap,
  }) {
    final color = _statusColor(status);

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.verified_user,
          color: color,
        ),
        title: Text(title),
        subtitle: Text(
          _formatDate(date),
        ),
        trailing: Chip(
          label: Text(status),
          backgroundColor:
              color.withValues(
            alpha: 0.15,
          ),
        ),
        onTap: _permissions.canManageDrivers
            ? onTap
            : null,
      ),
    );
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Expired':
        return Colors.red;

      case 'Due Soon':
        return Colors.orange;

      default:
        return Colors.green;
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day}/${date.month}/${date.year}';
  }
}