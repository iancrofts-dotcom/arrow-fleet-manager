import 'package:flutter/material.dart';

import '../../../../backend/users/central_managed_user.dart';
import '../../../../backend/users/central_user_management_repository.dart';
import '../../../../backend/users/supabase_user_management_gateway.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import 'central_add_user_screen.dart';
import 'central_edit_user_screen.dart';
import 'central_custom_roles_screen.dart';
import 'central_organisation_management_screen.dart';

class CentralUserManagementScreen extends StatefulWidget {
  const CentralUserManagementScreen({super.key, this.repository});

  final CentralUserManagementRepository? repository;

  @override
  State<CentralUserManagementScreen> createState() =>
      _CentralUserManagementScreenState();
}

class _CentralUserManagementScreenState
    extends State<CentralUserManagementScreen> {
  late final CentralUserManagementRepository _repository;
  final TextEditingController _search = TextEditingController();
  late Future<List<CentralManagedUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        const CentralUserManagementRepository(SupabaseUserManagementGateway());
    _reload();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _reload() {
    _usersFuture = _repository.listUsers();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _usersFuture;
  }

  Future<void> _add() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralAddUserScreen(repository: _repository),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _edit(CentralManagedUser user) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CentralEditUserScreen(user: user, repository: _repository),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _openCustomRoles() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CentralCustomRolesScreen(repository: _repository),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _removeFromCompany(CentralManagedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User From Company'),
        content: Text(
          'Remove ${user.username.isEmpty ? user.email : user.username} from the current company?\n\n'
          'If they belong to another FleetIQ company, their login and other memberships are preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.removeUserFromOrganisation(user.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to remove user from this company.'),
        ),
      );
      return;
    }
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageUsers) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to manage users.'),
        ),
      );
    }

    return AppPageScaffold(
      title: 'User Management',
      subtitle: 'Manage memberships and roles for the current company.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const CentralOrganisationManagementScreen(),
            ),
          ),
          icon: const Icon(Icons.apartment_outlined),
          label: const Text('Companies'),
        ),
        OutlinedButton.icon(
          onPressed: _openCustomRoles,
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Custom Roles'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add / Invite User'),
      ),
      child: Column(
        children: [
          SectionCard(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<CentralManagedUser>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingState(label: 'Loading users...');
                }
                if (snapshot.hasError) {
                  return AppErrorState(
                    title: 'Unable to load users',
                    message:
                        'Check that the FleetIQ manage-users function is deployed.',
                    onRetry: _refresh,
                  );
                }
                final query = _search.text.trim().toLowerCase();
                final users = (snapshot.data ?? const <CentralManagedUser>[])
                    .where((user) {
                      if (query.isEmpty) return true;
                      return user.username.toLowerCase().contains(query) ||
                          user.email.toLowerCase().contains(query) ||
                          user.displayRole.toLowerCase().contains(query);
                    })
                    .toList(growable: false);
                if (users.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 96),
                        AppEmptyState(
                          icon: Icons.manage_accounts_outlined,
                          title: 'No users found',
                          message:
                              'Add or invite a user, or change the search.',
                        ),
                      ],
                    ),
                  );
                }
                final currentId = AuthService.instance.currentUserId;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isCurrent = user.id == currentId;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (user.username.isNotEmpty
                                      ? user.username
                                      : user.email)
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(
                            user.username.isEmpty ? user.email : user.username,
                          ),
                          subtitle: Text(
                            '${user.displayRole} • '
                            '${user.isActive ? 'Active' : 'Inactive'}\n'
                            '${user.email}'
                            '${user.isDriverLinked ? ' • Driver linked' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: user.isDriverLinked
                                    ? 'Managed through Drivers'
                                    : 'Edit user',
                                onPressed: user.isDriverLinked
                                    ? null
                                    : () => _edit(user),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: isCurrent
                                    ? 'You cannot remove your own membership'
                                    : user.isDriverLinked
                                    ? 'Managed through Drivers'
                                    : 'Remove from company',
                                onPressed: isCurrent || user.isDriverLinked
                                    ? null
                                    : () => _removeFromCompany(user),
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
          ),
        ],
      ),
    );
  }
}
