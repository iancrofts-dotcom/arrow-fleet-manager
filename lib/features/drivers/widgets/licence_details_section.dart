import 'package:flutter/material.dart';

import '../../../shared/widgets/form_section.dart';

class LicenceDetailsSection extends StatelessWidget {
  final TextEditingController licenceNumberController;
  final DateTime? licenceExpiry;
  final VoidCallback onSelectExpiry;

  const LicenceDetailsSection({
    super.key,
    required this.licenceNumberController,
    required this.licenceExpiry,
    required this.onSelectExpiry,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Licence Details',
      subtitle: 'Driver licence information.',
      child: Column(
        children: [
          TextFormField(
            controller: licenceNumberController,
            decoration: const InputDecoration(
              labelText: 'Licence Number',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a licence number';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          InkWell(
            onTap: onSelectExpiry,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Licence Expiry',
              ),
              child: Text(
                licenceExpiry == null
                    ? 'Select expiry date'
                    : MaterialLocalizations.of(context)
                        .formatMediumDate(licenceExpiry!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}