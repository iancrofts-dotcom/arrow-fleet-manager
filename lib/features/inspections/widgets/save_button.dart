import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback? onSave;
  final bool isSaving;

  const SaveButton({
    super.key,
    required this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: isSaving ? null : onSave,
        icon: const Icon(Icons.save),
        label: Text(
          isSaving ? 'Submitting...' : 'Save Inspection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
