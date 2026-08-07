import 'package:flutter/material.dart';

class WizardProgress extends StatelessWidget {
  const WizardProgress({
    super.key,
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}