import 'package:flutter/material.dart';

import '../../backend/organisation/central_organisation.dart';
import '../../backend/organisation/central_organisation_service.dart';
import '../../config/backend_mode.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/services/permission_service.dart';

class CentralOrganisationSwitcher extends StatefulWidget {
  const CentralOrganisationSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  State<CentralOrganisationSwitcher> createState() =>
      _CentralOrganisationSwitcherState();
}

class _CentralOrganisationSwitcherState
    extends State<CentralOrganisationSwitcher> {
  late Future<List<CentralOrganisation>> _future;
  bool _switching = false;

  @override
  void initState() {
    super.initState();
    _future = CentralOrganisationService.instance.listMyOrganisations();
  }

  Future<void> _switch(String? id) async {
    if (id == null || _switching) return;
    final organisations = await _future;
    final selected = organisations.where((item) => item.id == id).firstOrNull;
    if (selected == null || selected.isCurrent) return;
    setState(() => _switching = true);
    try {
      await CentralOrganisationService.instance
          .ensureSafeToSwitchOrganisation();
      await CentralOrganisationService.instance.setActiveOrganisation(id);
      await AuthService.instance.refreshCentralProfile();
      if (!mounted) return;
      setState(() {
        _future = CentralOrganisationService.instance.listMyOrganisations();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Switched to ${selected.name}.')));
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to switch company.')),
      );
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.instance.backendMode != BackendMode.supabase ||
        PermissionService.instance.isDriver) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<List<CentralOrganisation>>(
      future: _future,
      builder: (context, snapshot) {
        final organisations = snapshot.data ?? const <CentralOrganisation>[];
        if (organisations.length <= 1) {
          final current = organisations
              .where((item) => item.isCurrent)
              .firstOrNull;
          if (current == null || widget.compact) return const SizedBox.shrink();
          return Text(
            current.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFD0D5DD), fontSize: 12),
          );
        }
        final current = organisations
            .where((item) => item.isCurrent)
            .firstOrNull;
        return DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: current?.id,
            isExpanded: !widget.compact,
            dropdownColor: const Color(0xFF18253B),
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            hint: const Text(
              'Select company',
              style: TextStyle(color: Colors.white),
            ),
            items: organisations
                .map(
                  (organisation) => DropdownMenuItem<String>(
                    value: organisation.id,
                    child: Text(
                      organisation.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _switching ? null : _switch,
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
