import 'package:flutter/material.dart';

class VehicleSafetyScheduleFields extends StatelessWidget {
  const VehicleSafetyScheduleFields({
    super.key,
    required this.title,
    required this.enabled,
    required this.intervalWeeks,
    required this.lastCompleted,
    required this.nextDue,
    required this.onEnabledChanged,
    required this.onIntervalChanged,
    required this.onLastCompletedChanged,
    required this.onNextDueChanged,
    this.disabled = false,
  });

  final String title;
  final bool enabled;
  final int intervalWeeks;
  final DateTime? lastCompleted;
  final DateTime? nextDue;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<DateTime?> onLastCompletedChanged;
  final ValueChanged<DateTime?> onNextDueChanged;
  final bool disabled;

  DateTime _plusWeeks(DateTime date, int weeks) =>
      DateTime(date.year, date.month, date.day).add(Duration(days: weeks * 7));

  String _format(DateTime? value) => value == null
      ? 'Not selected'
      : '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<DateTime?> _pick(BuildContext context, DateTime? value) =>
      showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: const Text('Track this recurring vehicle safety check.'),
        value: enabled,
        onChanged: disabled ? null : onEnabledChanged,
      ),
      if (enabled) ...[
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          initialValue: intervalWeeks,
          decoration: const InputDecoration(
            labelText: 'Reminder frequency',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 5, child: Text('Every 5 weeks')),
            DropdownMenuItem(value: 6, child: Text('Every 6 weeks')),
          ],
          onChanged: disabled
              ? null
              : (value) {
                  if (value == null) return;
                  onIntervalChanged(value);
                  if (lastCompleted != null) {
                    onNextDueChanged(_plusWeeks(lastCompleted!, value));
                  }
                },
        ),
        const SizedBox(height: 12),
        _DateRow(
          label: 'Last completed',
          value: _format(lastCompleted),
          enabled: !disabled,
          onPick: () async {
            final picked = await _pick(context, lastCompleted);
            if (picked == null) return;
            onLastCompletedChanged(picked);
            onNextDueChanged(_plusWeeks(picked, intervalWeeks));
          },
          onClear: lastCompleted == null || disabled
              ? null
              : () => onLastCompletedChanged(null),
        ),
        const SizedBox(height: 8),
        _DateRow(
          label: 'Next due',
          value: _format(nextDue),
          enabled: !disabled,
          onPick: () async {
            final picked = await _pick(context, nextDue);
            if (picked != null) onNextDueChanged(picked);
          },
          onClear: nextDue == null || disabled
              ? null
              : () => onNextDueChanged(null),
        ),
      ],
    ],
  );
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: enabled ? onPick : null,
          icon: const Icon(Icons.event_outlined),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text('$label: $value'),
          ),
        ),
      ),
      if (onClear != null) ...[
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Clear $label',
          onPressed: onClear,
          icon: const Icon(Icons.clear),
        ),
      ],
    ],
  );
}
