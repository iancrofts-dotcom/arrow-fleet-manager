import 'package:flutter/material.dart';

import '../../../core/navigation/compliance_navigation.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../models/fleet_compliance_summary.dart';
import '../services/fleet_compliance_service.dart';
import '../widgets/compliance_centre_content.dart';

class ComplianceCentreScreen extends StatefulWidget {
  const ComplianceCentreScreen({
    super.key,
    this.loadSummary,
    this.onOpenAttention,
  });

  final Future<FleetComplianceSummary> Function()? loadSummary;
  final Future<void> Function(
    BuildContext context,
    FleetComplianceAttentionItem item,
  )?
  onOpenAttention;

  @override
  State<ComplianceCentreScreen> createState() => _ComplianceCentreScreenState();
}

class _ComplianceCentreScreenState extends State<ComplianceCentreScreen> {
  late final Future<FleetComplianceSummary> Function() _loadSummary;
  late Future<FleetComplianceSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary = widget.loadSummary ?? FleetComplianceService().loadSummary;
    _summaryFuture = _loadSummary();
  }

  Future<void> _refresh() async {
    setState(() {
      _summaryFuture = _loadSummary();
    });
    await _summaryFuture;
  }

  Future<void> _openAttention(FleetComplianceAttentionItem item) async {
    final openAttention =
        widget.onOpenAttention ?? ComplianceNavigation.openAttention;
    await openAttention(context, item);
    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Compliance Centre',
    subtitle: 'Monitor vehicle and driver compliance across your fleet.',
    child: FutureBuilder<FleetComplianceSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading fleet compliance...');
        }
        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Unable to load compliance',
            message: 'Please try again.',
            onRetry: _refresh,
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ComplianceCentreContent(
            summary: snapshot.data!,
            onAttentionTap: _openAttention,
          ),
        );
      },
    ),
  );
}
