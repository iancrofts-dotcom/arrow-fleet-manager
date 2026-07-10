import 'package:flutter/material.dart';

import '../models/vehicle_compliance.dart';

class ComplianceStatusChip extends StatelessWidget {
  final ComplianceStatus status;

  const ComplianceStatusChip({
    super.key,
    required this.status,
  });

  Color _backgroundColor(BuildContext context) {
    switch (status) {
      case ComplianceStatus.valid:
        return Colors.green.shade100;

      case ComplianceStatus.dueSoon:
        return Colors.orange.shade100;

      case ComplianceStatus.overdue:
        return Colors.red.shade100;

      case ComplianceStatus.missing:
        return Colors.grey.shade300;
    }
  }

  Color _foregroundColor(BuildContext context) {
    switch (status) {
      case ComplianceStatus.valid:
        return Colors.green.shade800;

      case ComplianceStatus.dueSoon:
        return Colors.orange.shade800;

      case ComplianceStatus.overdue:
        return Colors.red.shade800;

      case ComplianceStatus.missing:
        return Colors.grey.shade800;
    }
  }

  IconData _icon() {
    switch (status) {
      case ComplianceStatus.valid:
        return Icons.check_circle;

      case ComplianceStatus.dueSoon:
        return Icons.warning_amber;

      case ComplianceStatus.overdue:
        return Icons.error;

      case ComplianceStatus.missing:
        return Icons.help_outline;
    }
  }

  String _text() {
    switch (status) {
      case ComplianceStatus.valid:
        return "Valid";

      case ComplianceStatus.dueSoon:
        return "Due Soon";

      case ComplianceStatus.overdue:
        return "Overdue";

      case ComplianceStatus.missing:
        return "Missing";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        _icon(),
        size: 18,
        color: _foregroundColor(context),
      ),
      label: Text(_text()),
      backgroundColor: _backgroundColor(context),
      labelStyle: TextStyle(
        color: _foregroundColor(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}