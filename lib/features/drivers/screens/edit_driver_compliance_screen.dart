import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../models/driver_compliance.dart';
import '../services/driver_compliance_service.dart';

class EditDriverComplianceScreen extends StatefulWidget {
  const EditDriverComplianceScreen({
    super.key,
    required this.driver,
    this.compliance,
  });

  final Driver driver;
  final DriverCompliance? compliance;

  @override
  State<EditDriverComplianceScreen> createState() =>
      _EditDriverComplianceScreenState();
}

class _EditDriverComplianceScreenState
    extends State<EditDriverComplianceScreen> {
  final DriverComplianceService _service =
      DriverComplianceService();

  late DateTime _licenceExpiry;
  late DateTime _cpcExpiry;
  late DateTime _medicalExpiry;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _licenceExpiry =
        widget.compliance?.licenceExpiry ??
            widget.driver.licenceExpiry ??
            DateTime(
              now.year + 5,
              now.month,
              now.day,
            );

    _cpcExpiry =
        widget.compliance?.cpcExpiry ??
            DateTime(
              now.year + 1,
              now.month,
              now.day,
            );

    _medicalExpiry =
        widget.compliance?.medicalExpiry ??
            DateTime(
              now.year + 1,
              now.month,
              now.day,
            );
  }

  Future<void> _pickDate(
    DateTime current,
    ValueChanged<DateTime> onSelected,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      onSelected(selected);
    });
  }

  Future<void> _save() async {
    final compliance = DriverCompliance(
      driverId: widget.driver.id!,
      licenceExpiry: _licenceExpiry,
      cpcExpiry: _cpcExpiry,
      medicalExpiry: _medicalExpiry,
    );

    await _service.save(compliance);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Compliance',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(widget.driver.fullName),
              subtitle: Text(
                widget.driver.licenceNumber,
              ),
            ),
          ),

          const SizedBox(height: 24),

          _dateTile(
            title: 'Licence Expiry',
            value: _licenceExpiry,
            onTap: () => _pickDate(
              _licenceExpiry,
              (date) => _licenceExpiry = date,
            ),
          ),

          _dateTile(
            title: 'CPC Expiry',
            value: _cpcExpiry,
            onTap: () => _pickDate(
              _cpcExpiry,
              (date) => _cpcExpiry = date,
            ),
          ),

          _dateTile(
            title: 'Medical Expiry',
            value: _medicalExpiry,
            onTap: () => _pickDate(
              _medicalExpiry,
              (date) => _medicalExpiry = date,
            ),
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text(
              'Save Compliance',
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event),
        title: Text(title),
        subtitle: Text(_formatDate(value)),
        trailing: const Icon(Icons.edit_calendar),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}