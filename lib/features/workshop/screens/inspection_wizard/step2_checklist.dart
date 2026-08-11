import 'package:flutter/material.dart';

import '../../models/inspection_wizard_data.dart';

class Step2Checklist extends StatelessWidget {
  final InspectionWizardData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const Step2Checklist({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        // ===============================================================
        // CHECKLIST CONTENT
        // ===============================================================
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.fact_check_outlined,
                            color: scheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inspection Checklist',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check each area of the vehicle.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Vehicle exterior
                    _ChecklistItem(
                      icon: Icons.directions_car_outlined,
                      title: 'Vehicle exterior',
                      subtitle: 'Bodywork, lights, mirrors and general condition',
                    ),

                    const SizedBox(height: 12),

                    // Tyres
                    _ChecklistItem(
                      icon: Icons.tire_repair_outlined,
                      title: 'Tyres and wheels',
                      subtitle: 'Condition, tread, pressure and wheel security',
                    ),

                    const SizedBox(height: 12),

                    // Safety
                    _ChecklistItem(
                      icon: Icons.warning_amber_outlined,
                      title: 'Safety equipment',
                      subtitle: 'Emergency equipment and safety items',
                    ),

                    const SizedBox(height: 12),

                    // Mechanical
                    _ChecklistItem(
                      icon: Icons.build_outlined,
                      title: 'Mechanical condition',
                      subtitle: 'Visible defects and mechanical concerns',
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Checklist responses, notes and photographs '
                              'will be added here.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ===============================================================
        // NAVIGATION
        // ===============================================================
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
    alignment: WrapAlignment.spaceBetween,
    runSpacing: 12,
    spacing: 12,
    children: [
      OutlinedButton.icon(
        onPressed: onPrevious,
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Back'),
      ),
      FilledButton.icon(
        onPressed: onNext,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Continue'),
      ),
    ],
  ),
),
      ],
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ChecklistItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: scheme.primary,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Icon(
            Icons.chevron_right_rounded,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}