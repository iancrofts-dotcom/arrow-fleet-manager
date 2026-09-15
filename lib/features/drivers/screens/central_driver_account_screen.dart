import 'package:flutter/material.dart';

import '../../../backend/drivers/backend_driver.dart';
import '../../../backend/drivers/backend_driver_repository.dart';
import '../../../backend/drivers/supabase_driver_gateway.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/central_password_service.dart';
import '../../auth/services/password_policy.dart';
import '../../documents/screens/central_document_list_screen.dart';
import 'central_driver_compliance_screen.dart';

/// Supabase-backed self-service account screen for a Driver.
///
/// Central mode must never fall back to the legacy local UserService account
/// editor. The authenticated profile's linked central Driver UUID is the
/// authority for the record shown here and for all self-service navigation.
class CentralDriverAccountScreen extends StatefulWidget {
  const CentralDriverAccountScreen({super.key, this.repository});

  final BackendDriverRepository? repository;

  @override
  State<CentralDriverAccountScreen> createState() =>
      _CentralDriverAccountScreenState();
}

class _CentralDriverAccountScreenState
    extends State<CentralDriverAccountScreen> {
  final CentralPasswordService _passwordService =
      const CentralPasswordService();
  late final BackendDriverRepository _repository;
  late Future<BackendDriver?> _future;
  late final String? _driverId;

  @override
  void initState() {
    super.initState();
    _driverId = AuthService.instance.currentBackendDriverId;
    _repository =
        widget.repository ?? BackendDriverRepository(SupabaseDriverGateway());
    _future = _driverId == null
        ? Future<BackendDriver?>.value()
        : _repository.getDriver(_driverId);
  }

  void _reload() {
    final driverId = _driverId;
    setState(() {
      _future = driverId == null
          ? Future<BackendDriver?>.value()
          : _repository.getDriver(driverId);
    });
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final password = TextEditingController();
    final confirm = TextEditingController();
    var obscure = true;
    var working = false;

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: !working,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: password,
                  obscureText: obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'New password',
                    suffixIcon: IconButton(
                      onPressed: working
                          ? null
                          : () => setLocal(() => obscure = !obscure),
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (value) => PasswordPolicy.validate(value ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirm,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  validator: (value) =>
                      value == password.text ? null : 'Passwords do not match.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: working ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: working
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setLocal(() => working = true);
                      try {
                        await _passwordService.changePassword(
                          newPassword: password.text,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (error) {
                        if (!context.mounted) return;
                        setLocal(() => working = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Password change failed: $error'),
                          ),
                        );
                      }
                    },
              child: working
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change password'),
            ),
          ],
        ),
      ),
    );

    password.dispose();
    confirm.dispose();
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your FleetIQ password has been changed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedInUser = AuthService.instance.currentUser;

    return AppPageScaffold(
      title: 'My Account',
      subtitle: 'Your central FleetIQ Driver account.',
      child: FutureBuilder<BackendDriver?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading your account...');
          }
          if (_driverId == null) {
            return const AppErrorState(
              message:
                  'This Supabase account is not linked to a central Driver record.',
            );
          }
          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load Driver account',
              message: '${snapshot.error}',
              onRetry: _reload,
            );
          }

          final driver = snapshot.data;
          if (driver == null || driver.id != _driverId) {
            return AppErrorState(
              message: 'Your linked central Driver record could not be found.',
              onRetry: _reload,
            );
          }

          final displayName = '${driver.firstName} ${driver.lastName}'.trim();
          final loginIdentity = driver.email?.trim().isNotEmpty == true
              ? driver.email!.trim()
              : (signedInUser?.username ?? 'Signed-in Driver');

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              SectionCard(
                title: 'Account Details',
                subtitle:
                    'This identity is managed by Supabase and linked to your Driver record.',
                child: Column(
                  children: [
                    _detail('Driver', displayName),
                    _detail('Login', loginIdentity),
                    _detail('Role', 'Driver'),
                    _detail('Licence Number', driver.licenceNumber),
                    if (driver.phone?.trim().isNotEmpty == true)
                      _detail('Phone', driver.phone!.trim()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Driver Self Service',
                subtitle:
                    'Changes below are saved to the central Supabase fleet database.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CentralDriverComplianceScreen(
                            driverId: driver.id,
                            driverName: displayName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Manage My Compliance'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CentralDocumentListScreen(
                            initialFilter: 'Driver',
                            entityType: 'driver',
                            entityId: driver.id,
                            ownerLabel: displayName,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.folder_shared_outlined),
                      label: const Text('Manage My Documents'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.password_outlined),
                      label: const Text('Change My Password'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detail(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    subtitle: Text(value),
  );
}
