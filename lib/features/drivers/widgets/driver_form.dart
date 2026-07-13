import 'package:flutter/material.dart';

import '../models/driver.dart';

class DriverForm extends StatefulWidget {
  final Driver? driver;
  final ValueChanged<Driver> onSubmit;

  const DriverForm({
    super.key,
    this.driver,
    required this.onSubmit,
  });

  @override
  State<DriverForm> createState() =>
      _DriverFormState();
}

class _DriverFormState extends State<DriverForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _licence;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  bool _active = true;

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

    _licence = TextEditingController(
      text: driver?.licenceNumber ?? '',
    );

    _phone = TextEditingController(
      text: driver?.phone ?? '',
    );

    _email = TextEditingController(
      text: driver?.email ?? '',
    );

    _active = driver?.active ?? true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _licence.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
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
        licenceNumber: _licence.text.trim(),
        licenceExpiry: widget.driver?.licenceExpiry,
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _firstName,
            decoration: const InputDecoration(
              labelText: 'First Name',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Enter a first name'
                    : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastName,
            decoration: const InputDecoration(
              labelText: 'Last Name',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Enter a last name'
                    : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licence,
            decoration: const InputDecoration(
              labelText: 'Licence Number',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Enter a licence number'
                    : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            keyboardType:
                TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Active Driver'),
            value: _active,
            onChanged: (value) {
              setState(() {
                _active = value;
              });
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            child: const Text('Save Driver'),
          ),
        ],
      ),
    );
  }
}