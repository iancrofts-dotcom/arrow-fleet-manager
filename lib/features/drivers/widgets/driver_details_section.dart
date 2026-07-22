import 'package:flutter/material.dart';

import '../../../shared/widgets/form_section.dart';

class DriverDetailsSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  const DriverDetailsSection({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Driver Details',
      subtitle: 'Basic information about the driver.',
      child: Column(
        children: [
          TextFormField(
            controller: firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a first name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a last name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
        ],
      ),
    );
  }
}