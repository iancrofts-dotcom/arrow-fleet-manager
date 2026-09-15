import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../services/central_password_service.dart';
import '../../services/central_profile_service.dart';
import '../../services/password_policy.dart';

class CentralMyProfileScreen extends StatefulWidget {
  const CentralMyProfileScreen({super.key});

  @override
  State<CentralMyProfileScreen> createState() => _CentralMyProfileScreenState();
}

class _CentralMyProfileScreenState extends State<CentralMyProfileScreen> {
  static const _profileService = CentralProfileService();
  static const _passwordService = CentralPasswordService();

  late Future<CentralProfileDetails> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _profileService.loadMyProfile();
  }

  void _reload() => setState(() => _future = _profileService.loadMyProfile());

  Future<void> _edit(CentralProfileDetails profile) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: profile.fullName);
    final phone = TextEditingController(text: profile.phone);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update my details'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 2 || text.contains('@')) {
                      return 'Enter your name, not an email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState?.validate() == true) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save details'),
          ),
        ],
      ),
    );
    if (save != true || !mounted) {
      name.dispose();
      phone.dispose();
      return;
    }
    setState(() => _saving = true);
    try {
      await _profileService.updateMyProfile(
        fullName: name.text,
        phone: phone.text,
      );
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile details updated.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile update failed: $error')),
        );
      }
    } finally {
      name.dispose();
      phone.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final key = GlobalKey<FormState>();
    final password = TextEditingController();
    final confirm = TextEditingController();
    var obscure = true;
    var working = false;
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Change password'),
          content: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: password,
                  obscureText: obscure,
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
                      if (key.currentState?.validate() != true) return;
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
    return AppPageScaffold(
      title: 'My Profile',
      subtitle: 'Update your FleetIQ user details and password.',
      child: FutureBuilder<CentralProfileDetails>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading your profile...');
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AppErrorState(
              title: 'Unable to load profile',
              message: '${snapshot.error ?? 'Profile unavailable.'}',
              onRetry: _reload,
            );
          }
          final profile = snapshot.data!;
          return ListView(
            children: [
              SectionCard(
                title: 'User details',
                child: Column(
                  children: [
                    _detail(
                      'Name',
                      profile.fullName.isEmpty ? 'Not set' : profile.fullName,
                    ),
                    _detail('Email / login', profile.email),
                    _detail(
                      'Phone',
                      profile.phone.isEmpty ? 'Not set' : profile.phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Account actions',
                subtitle:
                    'Your name is used on Workshop audit and sign-off records.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _edit(profile),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Update My Details'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _changePassword,
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
    subtitle: Text(value.trim().isEmpty ? '—' : value),
  );
}
