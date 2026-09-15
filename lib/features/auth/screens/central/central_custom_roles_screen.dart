import 'package:flutter/material.dart';

import '../../../../backend/users/central_custom_role.dart';
import '../../../../backend/users/central_user_management_repository.dart';
import '../../../../backend/users/supabase_user_management_gateway.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../services/permission_service.dart';

class CentralCustomRolesScreen extends StatefulWidget {
  const CentralCustomRolesScreen({super.key, this.repository});

  final CentralUserManagementRepository? repository;

  @override
  State<CentralCustomRolesScreen> createState() =>
      _CentralCustomRolesScreenState();
}

class _CentralCustomRolesScreenState extends State<CentralCustomRolesScreen> {
  late final CentralUserManagementRepository _repository;
  late Future<List<CentralCustomRole>> _rolesFuture;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        const CentralUserManagementRepository(SupabaseUserManagementGateway());
    _reload();
  }

  void _reload() => _rolesFuture = _repository.listCustomRoles();

  Future<void> _refresh() async {
    setState(_reload);
    await _rolesFuture;
  }

  Future<void> _edit([CentralCustomRole? role]) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _CustomRoleDialog(repository: _repository, role: role),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _delete(CentralCustomRole role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom Role?'),
        content: Text(
          'Delete “${role.name}”?\n\n'
          'FleetIQ will block deletion while any user is assigned to this role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Role'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteCustomRole(role.id);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete custom role.\n$error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    return AppPageScaffold(
      title: 'Custom Roles',
      subtitle: 'Create organisation-specific access roles and permissions.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_moderator_outlined),
        label: const Text('Create Role'),
      ),
      child: FutureBuilder<List<CentralCustomRole>>(
        future: _rolesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading custom roles...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load custom roles',
              message: 'Check the FleetIQ manage-users function and try again.',
              onRetry: _refresh,
            );
          }
          final roles = snapshot.data ?? const <CentralCustomRole>[];
          if (roles.isEmpty) {
            return const AppEmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'No custom roles',
              message:
                  'Use Create Role to build an organisation-specific permission set.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    title: Text(role.name),
                    subtitle: Text(
                      '${role.permissions.length} permissions • '
                      '${role.isActive ? 'Active' : 'Inactive'}'
                      '${role.description.trim().isEmpty ? '' : '\n${role.description.trim()}'}',
                    ),
                    isThreeLine: role.description.trim().isNotEmpty,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit role',
                          onPressed: () => _edit(role),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Delete role',
                          onPressed: () => _delete(role),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CustomRoleDialog extends StatefulWidget {
  const _CustomRoleDialog({required this.repository, this.role});

  final CentralUserManagementRepository repository;
  final CentralCustomRole? role;

  @override
  State<_CustomRoleDialog> createState() => _CustomRoleDialogState();
}

class _CustomRoleDialogState extends State<_CustomRoleDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late Set<String> _permissions;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.role?.name ?? '');
    _description = TextEditingController(text: widget.role?.description ?? '');
    _permissions = {...?widget.role?.permissions};
    _isActive = widget.role?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2 || _permissions.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final existing = widget.role;
      if (existing == null) {
        await widget.repository.createCustomRole(
          name: name,
          description: _description.text.trim(),
          permissions: _permissions,
        );
      } else {
        await widget.repository.updateCustomRole(
          role: existing,
          name: name,
          description: _description.text.trim(),
          permissions: _permissions,
          isActive: _isActive,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save custom role.\n$error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.role == null ? 'Create Custom Role' : 'Edit Custom Role',
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Role name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Permissions',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...FleetPermissionKey.selectable.entries.map(
              (entry) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value),
                value: _permissions.contains(entry.key),
                onChanged: (selected) => setState(() {
                  if (selected == true) {
                    _permissions.add(entry.key);
                  } else {
                    _permissions.remove(entry.key);
                  }
                }),
              ),
            ),
            if (widget.role != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Role active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Saving...' : 'Save Role'),
      ),
    ],
  );
}
