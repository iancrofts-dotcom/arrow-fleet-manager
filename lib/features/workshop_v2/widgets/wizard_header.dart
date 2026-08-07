import 'package:flutter/material.dart';

class WizardHeader extends StatelessWidget {
  const WizardHeader({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
  });

  final String title;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}