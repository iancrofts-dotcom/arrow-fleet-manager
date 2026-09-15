import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../services/driver_username_service.dart';
import 'driver_details_section.dart';
import 'driver_status_section.dart';
import 'licence_details_section.dart';
import 'login_details_section.dart';

class DriverForm extends StatefulWidget {
  final Driver? driver;
  final Future<void> Function(Driver driver, String password) onSubmit;
  final String submitLabel;
  final bool requireEmail;
  final bool invitationMode;

  const DriverForm({
    super.key,
    this.driver,
    required this.onSubmit,
    this.submitLabel = 'Save Driver',
    this.requireEmail = false,
    this.invitationMode = false,
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

    _firstName = TextEditingController(text: driver?.firstName ?? '');

    _lastName = TextEditingController(text: driver?.lastName ?? '');

    _licenceNumber = TextEditingController(text: driver?.licenceNumber ?? '');

    _phone = TextEditingController(text: driver?.phone ?? '');

    _email = TextEditingController(text: driver?.email ?? '');

    _username = TextEditingController(text: driver?.username ?? '');

    if (driver == null) {
      _firstName.addListener(_updateGeneratedUsername);
      _lastName.addListener(_updateGeneratedUsername);
      _updateGeneratedUsername();
    }

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

  void _updateGeneratedUsername() {
    final username = DriverUsernameService.baseUsername(
      _firstName.text,
      _lastName.text,
    );
    if (_username.text != username) {
      _username.value = TextEditingValue(
        text: username,
        selection: TextSelection.collapsed(offset: username.length),
      );
    }
  }

  Future<void> _selectLicenceExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _licenceExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _licenceExpiry = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSubmit(
      Driver(
        id: widget.driver?.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        licenceNumber: _licenceNumber.text.trim(),
        licenceExpiry: _licenceExpiry,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        username: _username.text.trim().isEmpty ? null : _username.text.trim(),
        isActive: _isActive,
      ),
      _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DriverDetailsSection(
            firstNameController: _firstName,
            lastNameController: _lastName,
            phoneController: _phone,
            emailController: _email,
            requireEmail: widget.requireEmail,
          ),
          LicenceDetailsSection(
            licenceNumberController: _licenceNumber,
            licenceExpiry: _licenceExpiry,
            onSelectExpiry: _selectLicenceExpiry,
          ),
          if (!widget.invitationMode)
            LoginDetailsSection(
              usernameController: _username,
              passwordController: _password,
              confirmPasswordController: _confirmPassword,
              showPasswordFields: widget.driver == null,
              usernameReadOnly: widget.driver == null,
            )
          else
            const _InvitationAccountSection(),
          DriverStatusSection(
            isActive: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(
              widget.invitationMode ? Icons.send_outlined : Icons.save,
            ),
            label: Text(widget.submitLabel),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InvitationAccountSection extends StatelessWidget {
  const _InvitationAccountSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_email_read_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Driver invitation',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'FleetIQ will send the Driver a secure email link so they can choose their own password. Administrators do not create or view Driver passwords.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _InviteStep(number: '1', text: 'Create the Driver profile.'),
            const _InviteStep(
              number: '2',
              text: 'Send the secure invitation email.',
            ),
            const _InviteStep(
              number: '3',
              text: 'Driver chooses their own password.',
            ),
            const _InviteStep(
              number: '4',
              text: 'Driver signs in using their email address.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteStep extends StatelessWidget {
  const _InviteStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          child: Text(number, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
