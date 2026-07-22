import 'package:flutter/material.dart';

import '../models/driver.dart';
import 'driver_details_section.dart';
import 'driver_status_section.dart';
import 'licence_details_section.dart';
import 'login_details_section.dart';

class DriverForm extends StatefulWidget {
  final Driver? driver;
  final ValueChanged<Driver> onSubmit;

  const DriverForm({
    super.key,
    this.driver,
    required this.onSubmit,
  });

  @override
  State<DriverForm> createState() => _DriverFormState();
}

class _DriverFormState extends State<DriverForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _licenceNumber;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;

  DateTime? _licenceExpiry;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();

    final driver = widget.driver;

    _firstName = TextEditingController(
      text: driver?.firstName ?? '',
    );

    _lastName = TextEditingController(
      text: driver?.lastName ?? '',
    );

    _licenceNumber = TextEditingController(
      text: driver?.licenceNumber ?? '',
    );

    _phone = TextEditingController(
      text: driver?.phone ?? '',
    );

    _email = TextEditingController(
      text: driver?.email ?? '',
    );

    _username = TextEditingController(
      text: driver?.username ?? '',
    );

    _password = TextEditingController();

    _confirmPassword = TextEditingController();

    _licenceExpiry = driver?.licenceExpiry;

    _isActive = driver?.isActive ?? true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _licenceNumber.dispose();
    _phone.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();

    super.dispose();
  }

  Future<void> _selectLicenceExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _licenceExpiry ??
          DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _licenceExpiry = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSubmit(
      Driver(
        id: widget.driver?.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        licenceNumber: _licenceNumber.text.trim(),
        licenceExpiry: _licenceExpiry,
        phone: _phone.text.trim().isEmpty
            ? null
            : _phone.text.trim(),
        email: _email.text.trim().isEmpty
            ? null
            : _email.text.trim(),
        username: _username.text.trim().isEmpty
            ? null
            : _username.text.trim(),
        isActive: _isActive,
      ),
    );

    // Password creation/update will be handled
    // by UserService in Phase 5.
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DriverDetailsSection(
            firstNameController: _firstName,
            lastNameController: _lastName,
            phoneController: _phone,
            emailController: _email,
          ),
          LicenceDetailsSection(
            licenceNumberController: _licenceNumber,
            licenceExpiry: _licenceExpiry,
            onSelectExpiry: _selectLicenceExpiry,
          ),
          LoginDetailsSection(
            usernameController: _username,
            passwordController: _password,
            confirmPasswordController: _confirmPassword,
          ),
          DriverStatusSection(
            isActive: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save),
            label: const Text('Save Driver'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}