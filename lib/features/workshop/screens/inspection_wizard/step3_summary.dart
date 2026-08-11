import 'package:flutter/material.dart';

import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_wizard_data.dart';

class Step3Summary extends StatelessWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step3Summary({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  List<InspectionChecklistItem> get items =>
      data.checklistItems;

  int get passed =>
      items.where((item) => item.passed).length;

  int get advisory =>
      items.where((item) => item.advisoryOnly).length;

  int get failed =>
      items.where((item) => item.failed).length;

  int get completed =>
      items.where((item) => item.completed).length;

  int get repairs =>
      items.where((item) => item.repairRequired).length;

  int get totalPhotos =>
      items.fold(
        0,
        (total, item) => total + item.photos.length,
      );

  int get score {
    if (items.isEmpty) {
      return 0;
    }

    return ((passed / items.length) * 100).round();
  }

  bool get roadworthy =>
      failed == 0;

  List<InspectionChecklistItem> get issues =>
      items
          .where(
            (item) =>
                item.failed ||
                item.advisoryOnly,
          )
          .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        // ===================================================================
        // SUMMARY HEADER
        // ===================================================================

        Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            18,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.summarize_outlined,
                  color: scheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspection Summary',
                      style: theme.textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Review the inspection before moving to repairs.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        color:
                            scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ===================================================================
        // MAIN CONTENT
        // ===================================================================

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // =============================================================
              // VEHICLE / TECHNICIAN
              // =============================================================

              _VehicleSummaryCard(
                registration:
                    data.registration,
                fleetNumber:
                    data.fleetNumber,
                mileage:
                    data.mileage,
                technician:
                    data.technicianName ??
                        data.technician,
              ),

              const SizedBox(height: 16),

              // =============================================================
              // RESULT
              // =============================================================

              _ResultCard(
                score: score,
                completed: completed,
                total: items.length,
                passed: passed,
                advisory: advisory,
                failed: failed,
                repairs: repairs,
                roadworthy: roadworthy,
              ),

              const SizedBox(height: 16),

              // =============================================================
              // PHOTOS / NOTES
              // =============================================================

              _EvidenceCard(
                totalPhotos: totalPhotos,
                itemsWithNotes: items
                    .where(
                      (item) =>
                          item.notes.trim().isNotEmpty,
                    )
                    .length,
              ),

              const SizedBox(height: 20),

              // =============================================================
              // ISSUES
              // =============================================================

              if (issues.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.report_problem_outlined,
                      color: scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Items Requiring Attention',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                for (final item in issues) ...[
                  _IssueCard(
                    item: item,
                  ),
                  const SizedBox(height: 10),
                ],
              ] else
                _NoIssuesCard(),
            ],
          ),
        ),

        // ===================================================================
        // FOOTER
        // ===================================================================

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(
                color: scheme.outlineVariant,
              ),
            ),
          ),
          child: Wrap(
            alignment:
                WrapAlignment.spaceBetween,
            runSpacing: 12,
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text('Back'),
              ),
              FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                ),
                label: const Text(
                  'Continue to Repairs',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// VEHICLE SUMMARY
// =============================================================================

class _VehicleSummaryCard extends StatelessWidget {
  final String? registration;
  final String? fleetNumber;
  final int? mileage;
  final String? technician;

  const _VehicleSummaryCard({
    required this.registration,
    required this.fleetNumber,
    required this.mileage,
    required this.technician,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inspection Details',
            style: theme.textTheme.titleLarge
                ?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _DetailItem(
                icon: Icons.directions_car_outlined,
                label: 'Registration',
                value:
                    registration?.isNotEmpty == true
                        ? registration!
                        : 'Not specified',
              ),

              _DetailItem(
                icon: Icons.numbers_outlined,
                label: 'Fleet Number',
                value:
                    fleetNumber?.isNotEmpty == true
                        ? fleetNumber!
                        : 'Not specified',
              ),

              _DetailItem(
                icon: Icons.speed_outlined,
                label: 'Mileage',
                value: mileage != null
                    ? '${mileage!} miles'
                    : 'Not specified',
              ),

              _DetailItem(
                icon: Icons.person_outline,
                label: 'Technician',
                value:
                    technician?.isNotEmpty == true
                        ? technician!
                        : 'Not specified',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DETAIL ITEM
// =============================================================================

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return SizedBox(
      width: 230,
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: scheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                        scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RESULT CARD
// =============================================================================

class _ResultCard extends StatelessWidget {
  final int score;
  final int completed;
  final int total;
  final int passed;
  final int advisory;
  final int failed;
  final int repairs;
  final bool roadworthy;

  const _ResultCard({
    required this.score,
    required this.completed,
    required this.total,
    required this.passed,
    required this.advisory,
    required this.failed,
    required this.repairs,
    required this.roadworthy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: roadworthy
              ? scheme.primary
                  .withValues(alpha: 0.35)
              : scheme.error
                  .withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: roadworthy
                      ? scheme.primaryContainer
                      : scheme.errorContainer,
                ),
                child: Center(
                  child: Text(
                    '$score%',
                    style: theme.textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight:
                          FontWeight.w900,
                      color: roadworthy
                          ? scheme.primary
                          : scheme.error,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      roadworthy
                          ? 'Vehicle Roadworthy'
                          : 'Vehicle Not Roadworthy',
                      style: theme.textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed of $total checklist items completed',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(
                        color:
                            scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ResultStat(
                icon: Icons.check_circle,
                label: 'Pass',
                value: passed,
              ),
              _ResultStat(
                icon: Icons.warning_amber,
                label: 'Advisory',
                value: advisory,
              ),
              _ResultStat(
                icon: Icons.cancel,
                label: 'Defect',
                value: failed,
              ),
              _ResultStat(
                icon: Icons.build_outlined,
                label: 'Repairs',
                value: repairs,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RESULT STAT
// =============================================================================

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _ResultStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 19,
            color: scheme.primary,
          ),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EVIDENCE CARD
// =============================================================================

class _EvidenceCard extends StatelessWidget {
  final int totalPhotos;
  final int itemsWithNotes;

  const _EvidenceCard({
    required this.totalPhotos,
    required this.itemsWithNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file_outlined,
            color: scheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Inspection evidence',
              style: theme.textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$totalPhotos photos',
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$itemsWithNotes notes',
            style: theme.textTheme.bodyMedium
                ?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ISSUE CARD
// =============================================================================

class _IssueCard extends StatelessWidget {
  final InspectionChecklistItem item;

  const _IssueCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isDefect = item.failed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDefect
            ? scheme.errorContainer
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefect
              ? scheme.error
                  .withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isDefect
                    ? Icons.cancel
                    : Icons.warning_amber,
                color: isDefect
                    ? scheme.error
                    : scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              if (item.photos.isNotEmpty)
                Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_outlined,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.photos.length}',
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            item.category,
            style: theme.textTheme.bodySmall
                ?.copyWith(
              color:
                  scheme.onSurfaceVariant,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          if (item.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface
                    .withValues(alpha: 0.7),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.notes,
                      style: theme.textTheme
                          .bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// NO ISSUES
// =============================================================================

class _NoIssuesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 32,
            color: scheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'No advisories or defects have been recorded.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}