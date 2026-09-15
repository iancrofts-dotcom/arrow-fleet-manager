import 'package:flutter/material.dart';

import '../../../../backend/users/central_user_management_repository.dart';
import '../../../../backend/users/supabase_user_management_gateway.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../models/user_role.dart';
import '../../services/permission_service.dart';
import '../../widgets/central/central_user_form.dart';

class CentralAddUserScreen extends StatefulWidget {
  const CentralAddUserScreen({super.key, this.repository});

  final CentralUserManagementRepository? repository;

  @override
  State<CentralAddUserScreen> createState() => _CentralAddUserScreenState();
}

class _CentralAddUserScreenState extends State<CentralAddUserScreen> {
  late final CentralUserManagementRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        const CentralUserManagementRepository(SupabaseUserManagementGateway());
  }

  Future<void> _save(
    String email,
    String username,
    UserRole role,
    String? customRoleId,
    bool isActive,
  ) async {
    try {
      await _repository.inviteOrAddUser(
        email: email,
        username: username,
        role: role,
        customRoleId: customRoleId,
        isActive: isActive,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to add user.\n$error')));
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageUsers) {
      return const Scaffold(
        body: Center(
          child: Text('You do not have permission to create users.'),
        ),
      );
    }
    return AppPageScaffold(
      title: 'Add User',
      subtitle: 'Add an existing FleetIQ login or send a secure invitation.',
      child: CentralUserForm(repository: _repository, onSave: _save),
    );
  }
}
