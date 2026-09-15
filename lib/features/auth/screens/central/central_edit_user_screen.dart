import 'package:flutter/material.dart';

import '../../../../backend/users/central_managed_user.dart';
import '../../../../backend/users/central_user_management_repository.dart';
import '../../../../backend/users/supabase_user_management_gateway.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../models/user_role.dart';
import '../../services/permission_service.dart';
import '../../widgets/central/central_user_form.dart';

class CentralEditUserScreen extends StatefulWidget {
  const CentralEditUserScreen({super.key, required this.user, this.repository});

  final CentralManagedUser user;
  final CentralUserManagementRepository? repository;

  @override
  State<CentralEditUserScreen> createState() => _CentralEditUserScreenState();
}

class _CentralEditUserScreenState extends State<CentralEditUserScreen> {
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
      await _repository.updateUser(
        user: widget.user,
        email: email,
        username: username,
        role: role,
        customRoleId: customRoleId,
        isActive: isActive,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update membership.\n$error')),
      );
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageUsers) {
      return const Scaffold(
        body: Center(child: Text('You do not have permission to edit users.')),
      );
    }
    if (widget.user.isDriverLinked) {
      return AppPageScaffold(
        title: 'Driver Account',
        subtitle: 'Driver-linked accounts are managed through Drivers.',
        child: const Center(
          child: Text('This account is linked to a Driver record.'),
        ),
      );
    }
    return AppPageScaffold(
      title: 'Edit Membership',
      subtitle: 'Update access for the current company only.',
      child: CentralUserForm(
        user: widget.user,
        repository: _repository,
        onSave: _save,
      ),
    );
  }
}
