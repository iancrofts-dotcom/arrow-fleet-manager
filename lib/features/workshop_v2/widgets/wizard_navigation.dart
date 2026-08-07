import 'package:flutter/material.dart';

class WizardNavigation extends StatelessWidget {
  const WizardNavigation({
    super.key,
    required this.isFirstStep,
    required this.isLastStep,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isFirstStep;
  final bool isLastStep;

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: isFirstStep ? null : onPrevious,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Previous'),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: onNext,
          icon: Icon(
            isLastStep
                ? Icons.check
                : Icons.arrow_forward,
          ),
          label: Text(
            isLastStep
                ? 'Finish'
                : 'Continue',
          ),
        ),
      ],
    );
  }
}