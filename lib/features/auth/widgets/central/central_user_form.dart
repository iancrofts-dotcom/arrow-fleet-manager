import 'package:flutter/material.dart';

import '../../../../backend/users/central_custom_role.dart';
import '../../../../backend/users/central_managed_user.dart';
import '../../../../backend/users/central_user_management_repository.dart';
import '../../models/user_role.dart';

class CentralUserForm extends StatefulWidget {
  const CentralUserForm({
    super.key,
    this.user,
    required this.repository,
    required this.onSave,
  });

  final CentralManagedUser? user;
  final CentralUserManagementRepository repository;
  final Future<void> Function(
    String email,
    String username,
    UserRole role,
    String? customRoleId,
    bool isActive,
  )
  onSave;

  @override
  State<CentralUserForm> createState() => _CentralUserFormState();
}

class _CentralUserFormState extends State<CentralUserForm> {
  static const _builtInRoles = <UserRole>[
    UserRole.technician,
    UserRole.manager,
    UserRole.workshop,
    UserRole.admin,
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _username;
  late UserRole _role;
  String? _customRoleId;
  late bool _isActive;
  bool _saving = false;
  late Future<List<CentralCustomRole>> _customRolesFuture;

  bool get _editing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _email = TextEditingController(text: user?.email ?? '');
    _username = TextEditingController(text: user?.username ?? '');
    _role = user?.role == UserRole.driver
        ? UserRole.technician
        : user?.role ?? UserRole.technician;
    _customRoleId = user?.customRoleId;
    _isActive = user?.isActive ?? true;
    _customRolesFuture = widget.repository.listCustomRoles();
  }

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final effectiveRole = _customRoleId == null ? _role : UserRole.manager;
      await widget.onSave(
        _email.text.trim(),
        _username.text.trim(),
        effectiveRole,
        _customRoleId,
        _isActive,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CentralCustomRole>>(
    future: _customRolesFuture,
    builder: (context, snapshot) {
      final customRoles =
          snapshot.data
              ?.where((role) => role.isActive || role.id == _customRoleId)
              .toList(growable: false) ??
          const <CentralCustomRole>[];
      return Form(
        key: _formKey,
        child: ListView(
          children: [
            if (!_editing)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'FleetIQ will add an existing login to this company, or send a secure invitation when the email is new. Administrators never set user passwords.',
                ),
              ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              readOnly: _editing,
              decoration: InputDecoration(
                labelText: 'Email *',
                helperText: _editing
                    ? 'Login identity is shared across company memberships.'
                    : null,
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              readOnly: _editing,
              decoration: InputDecoration(
                labelText: 'Display name *',
                helperText: _editing
                    ? 'Display identity is shared across company memberships.'
                    : null,
              ),
              validator: (value) => value?.trim().isEmpty == true
                  ? 'Enter a display name.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _customRoleId == null
                  ? 'builtin:${_role.name}'
                  : 'custom:$_customRoleId',
              decoration: const InputDecoration(labelText: 'Role *'),
              items: [
                ..._builtInRoles.map(
                  (role) => DropdownMenuItem(
                    value: 'builtin:${role.name}',
                    child: Text(role.displayName),
                  ),
                ),
                ...customRoles.map(
                  (role) => DropdownMenuItem(
                    value: 'custom:${role.id}',
                    child: Text('${role.name} (Custom)'),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  if (value.startsWith('custom:')) {
                    _customRoleId = value.substring('custom:'.length);
                  } else {
                    _customRoleId = null;
                    final name = value.substring('builtin:'.length);
                    _role = UserRole.values.firstWhere(
                      (role) => role.name == name,
                    );
                  }
                });
              },
            ),
            if (snapshot.hasError) ...[
              const SizedBox(height: 8),
              const Text(
                'Custom roles could not be loaded. Built-in roles remain available.',
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active membership'),
              subtitle: const Text('Applies only to the current company.'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _editing
                          ? Icons.save_outlined
                          : Icons.mark_email_read_outlined,
                    ),
              label: Text(
                _saving
                    ? 'Saving...'
                    : _editing
                    ? 'Save Membership'
                    : 'Add / Invite User',
              ),
            ),
          ],
        ),
      );
    },
  );
}
