import 'package:flutter/material.dart';

import '../../../../backend/backend_client.dart';
import '../../../../backend/organisation/central_organisation.dart';
import '../../../../backend/organisation/central_organisation_member.dart';
import '../../../../backend/organisation/central_organisation_service.dart';
import '../../../../backend/organisation/central_organisation_settings.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';
import '../../../legal/screens/central_legal_centre_screen.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';

class CentralOrganisationManagementScreen extends StatefulWidget {
  const CentralOrganisationManagementScreen({super.key});

  @override
  State<CentralOrganisationManagementScreen> createState() =>
      _CentralOrganisationManagementScreenState();
}

class _CentralOrganisationManagementScreenState
    extends State<CentralOrganisationManagementScreen> {
  final _service = CentralOrganisationService.instance;
  late Future<List<CentralOrganisation>> _organisations;
  late Future<List<CentralOrganisationMember>> _members;
  late Future<CentralOrganisationSettings> _settings;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _organisations = _service.listMyOrganisations();
    _members = _service.listCurrentOrganisationMembers();
    _settings = _service.getCurrentOrganisationSettings();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_organisations, _members, _settings]);
  }

  Future<void> _switch(CentralOrganisation organisation) async {
    if (organisation.isCurrent) return;
    try {
      await _service.ensureSafeToSwitchOrganisation();
      await _service.setActiveOrganisation(organisation.id);
      await AuthService.instance.refreshCentralProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${organisation.name}.')),
      );
      await _refresh();
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to switch company. Please try again.'),
        ),
      );
    }
  }

  Future<void> _create() async {
    final result = await showDialog<({String name, String slug})>(
      context: context,
      builder: (_) => const _CreateOrganisationDialog(),
    );
    if (result == null) return;
    try {
      await _service.createOrganisation(name: result.name, slug: result.slug);
      await AuthService.instance.refreshCentralProfile();
      if (mounted) await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to create company. Check the name and company code.',
          ),
        ),
      );
    }
  }

  Future<void> _transferOwnership(
    CentralOrganisationSettings settings,
    List<CentralOrganisationMember> members,
  ) async {
    final candidates = members
        .where(
          (member) =>
              member.isActive &&
              member.role == 'administrator' &&
              member.userId != settings.ownerUserId,
        )
        .toList(growable: false);
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add another active Administrator before transferring ownership.',
          ),
        ),
      );
      return;
    }
    final selected = await showDialog<CentralOrganisationMember>(
      context: context,
      builder: (_) => _TransferOwnershipDialog(candidates: candidates),
    );
    if (selected == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transfer Company Ownership?'),
        content: Text(
          'Transfer ownership to ${selected.username.isEmpty ? selected.email : selected.username}? '
          'They will become the protected company owner and must remain an active Administrator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Transfer Ownership'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.transferCurrentOrganisationOwnership(selected.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company ownership transferred.')),
      );
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to transfer company ownership.')),
      );
    }
  }

  Future<void> _editSettings(CentralOrganisationSettings settings) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _OrganisationSettingsDialog(settings: settings, service: _service),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    return AppPageScaffold(
      title: 'Companies',
      subtitle: 'Manage company context, details and memberships.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add Company'),
      ),
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            SectionCard(
              child: ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Legal & Privacy Centre'),
                subtitle: const Text(
                  'Terms, privacy, DPA, security, retention and GDPR requests.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CentralLegalCentreScreen(),
                  ),
                ),
              ),
            ),
            SectionCard(
              child: FutureBuilder<List<CentralOrganisation>>(
                future: _organisations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingState(label: 'Loading companies...');
                  }
                  if (snapshot.hasError) {
                    return AppErrorState(
                      title: 'Unable to load companies',
                      message: 'Check your connection and try again.',
                      onRetry: _refresh,
                    );
                  }
                  final organisations =
                      snapshot.data ?? const <CentralOrganisation>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Your companies',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final organisation in organisations)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Icon(
                              organisation.isCurrent
                                  ? Icons.business
                                  : Icons.apartment_outlined,
                            ),
                          ),
                          title: Text(organisation.name),
                          subtitle: Text(organisation.slug),
                          trailing: organisation.isCurrent
                              ? const Chip(label: Text('Current'))
                              : TextButton(
                                  onPressed: () => _switch(organisation),
                                  child: const Text('Switch'),
                                ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: FutureBuilder<CentralOrganisationSettings>(
                future: _settings,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingState(
                      label: 'Loading company settings...',
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return AppErrorState(
                      title: 'Unable to load company settings',
                      message: 'Check your connection and try again.',
                      onRetry: _refresh,
                    );
                  }
                  final settings = snapshot.data!;
                  final details = <String>[
                    if (settings.legalName.isNotEmpty) settings.legalName,
                    if (settings.contactEmail.isNotEmpty) settings.contactEmail,
                    if (settings.phone.isNotEmpty) settings.phone,
                    if (settings.postcode.isNotEmpty) settings.postcode,
                  ].join(' • ');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.tune_outlined),
                    ),
                    title: const Text('Company settings'),
                    subtitle: Text(
                      details.isEmpty
                          ? 'Add company identity and report/contact details.'
                          : details,
                    ),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => _editSettings(settings),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<CentralOrganisationSettings>(
              future: _settings,
              builder: (context, settingsSnapshot) =>
                  FutureBuilder<List<CentralOrganisationMember>>(
                    future: _members,
                    builder: (context, membersSnapshot) {
                      if (!settingsSnapshot.hasData ||
                          !membersSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final settings = settingsSnapshot.data!;
                      final members = membersSnapshot.data!;
                      final currentUserId =
                          BackendClient.client.auth.currentUser?.id;
                      final owner = members.where(
                        (member) => member.userId == settings.ownerUserId,
                      );
                      final ownerLabel = owner.isEmpty
                          ? 'Protected company owner'
                          : (owner.first.username.isEmpty
                                ? owner.first.email
                                : owner.first.username);
                      return SectionCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.admin_panel_settings_outlined),
                          ),
                          title: const Text('Company ownership'),
                          subtitle: Text(ownerLabel),
                          trailing: currentUserId == settings.ownerUserId
                              ? FilledButton.tonalIcon(
                                  onPressed: () =>
                                      _transferOwnership(settings, members),
                                  icon: const Icon(Icons.swap_horiz_outlined),
                                  label: const Text('Transfer'),
                                )
                              : const Chip(label: Text('Owner protected')),
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              child: FutureBuilder<List<CentralOrganisationMember>>(
                future: _members,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingState(
                      label: 'Loading company members...',
                    );
                  }
                  if (snapshot.hasError) {
                    return AppErrorState(
                      title: 'Unable to load company members',
                      message: 'Only current-company members are shown here.',
                      onRetry: _refresh,
                    );
                  }
                  final members =
                      snapshot.data ?? const <CentralOrganisationMember>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Current company members',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/users'),
                            icon: const Icon(Icons.manage_accounts_outlined),
                            label: const Text('Manage Users'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final member in members)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(
                            member.username.isEmpty
                                ? member.email
                                : member.username,
                          ),
                          subtitle: Text(
                            '${member.email}${member.customRoleName == null ? ' • ${member.role}' : ' • ${member.customRoleName}'}',
                          ),
                          trailing: Text(
                            member.isActive ? 'Active' : 'Inactive',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferOwnershipDialog extends StatelessWidget {
  const _TransferOwnershipDialog({required this.candidates});

  final List<CentralOrganisationMember> candidates;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose New Company Owner'),
    content: SizedBox(
      width: 500,
      child: ListView(
        shrinkWrap: true,
        children: [
          const Text(
            'Only active Administrators can become the company owner.',
          ),
          const SizedBox(height: 12),
          for (final member in candidates)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(
                member.username.isEmpty ? member.email : member.username,
              ),
              subtitle: Text(member.email),
              onTap: () => Navigator.pop(context, member),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    ],
  );
}

class _CreateOrganisationDialog extends StatefulWidget {
  const _CreateOrganisationDialog();

  @override
  State<_CreateOrganisationDialog> createState() =>
      _CreateOrganisationDialogState();
}

class _CreateOrganisationDialogState extends State<_CreateOrganisationDialog> {
  final _name = TextEditingController();
  final _slug = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    super.dispose();
  }

  String _normaliseSlug(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add Company'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Company name *'),
            onChanged: (value) {
              if (_slug.text.isEmpty) _slug.text = _normaliseSlug(value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slug,
            decoration: const InputDecoration(
              labelText: 'Company code *',
              helperText: 'Lowercase letters, numbers and hyphens.',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final name = _name.text.trim();
          final slug = _normaliseSlug(_slug.text);
          if (name.length < 2 || slug.length < 2) return;
          Navigator.pop(context, (name: name, slug: slug));
        },
        child: const Text('Create Company'),
      ),
    ],
  );
}

class _OrganisationSettingsDialog extends StatefulWidget {
  const _OrganisationSettingsDialog({
    required this.settings,
    required this.service,
  });

  final CentralOrganisationSettings settings;
  final CentralOrganisationService service;

  @override
  State<_OrganisationSettingsDialog> createState() =>
      _OrganisationSettingsDialogState();
}

class _OrganisationSettingsDialogState
    extends State<_OrganisationSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _legalName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _town;
  late final TextEditingController _postcode;
  late final TextEditingController _companyNumber;
  late final TextEditingController _reportFooter;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _name = TextEditingController(text: settings.name);
    _legalName = TextEditingController(text: settings.legalName);
    _email = TextEditingController(text: settings.contactEmail);
    _phone = TextEditingController(text: settings.phone);
    _address1 = TextEditingController(text: settings.addressLine1);
    _address2 = TextEditingController(text: settings.addressLine2);
    _town = TextEditingController(text: settings.townCity);
    _postcode = TextEditingController(text: settings.postcode);
    _companyNumber = TextEditingController(text: settings.companyNumber);
    _reportFooter = TextEditingController(text: settings.reportFooter);
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _legalName,
      _email,
      _phone,
      _address1,
      _address2,
      _town,
      _postcode,
      _companyNumber,
      _reportFooter,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.updateCurrentOrganisationSettings(
        name: _name.text,
        legalName: _legalName.text,
        contactEmail: _email.text,
        phone: _phone.text,
        addressLine1: _address1.text,
        addressLine2: _address2.text,
        townCity: _town.text,
        postcode: _postcode.text,
        companyNumber: _companyNumber.text,
        reportFooter: _reportFooter.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save company settings.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Company Settings'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Display name *', isRequired: true),
              _field(_legalName, 'Legal / registered name'),
              _field(_email, 'Contact email'),
              _field(_phone, 'Phone'),
              _field(_address1, 'Address line 1'),
              _field(_address2, 'Address line 2'),
              _field(_town, 'Town / city'),
              _field(_postcode, 'Postcode'),
              _field(_companyNumber, 'Company number'),
              _field(
                _reportFooter,
                'Report footer / trading note',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(_saving ? 'Saving...' : 'Save Settings'),
      ),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: isRequired
          ? (value) => (value?.trim().length ?? 0) < 2
                ? 'Enter at least 2 characters.'
                : null
          : null,
    ),
  );
}
