import 'package:flutter/material.dart';

import '../../../backend/workshop/backend_workshop_repository.dart';
import '../../../backend/workshop/backend_workshop_template.dart';
import '../../../backend/workshop/backend_workshop_writes.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class CentralWorkshopTemplateWizardScreen extends StatefulWidget {
  const CentralWorkshopTemplateWizardScreen({
    super.key,
    required this.repository,
    this.template,
  });

  final BackendWorkshopRepository repository;
  final BackendWorkshopTemplate? template;

  @override
  State<CentralWorkshopTemplateWizardScreen> createState() =>
      _CentralWorkshopTemplateWizardScreenState();
}

class _CentralWorkshopTemplateWizardScreenState
    extends State<CentralWorkshopTemplateWizardScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final List<_TemplateDraftItem> _items = [];
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  bool _active = true;
  String _inspectionType = 'defectInspection';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final template = widget.template;
    if (template != null) {
      _name.text = template.name;
      _description.text = template.description;
      _inspectionType = template.inspectionType ?? 'defectInspection';
      _active = template.isActive;
      final existing = await widget.repository.listTemplateItems(template.id);
      for (final item in existing) {
        _items.add(
          _TemplateDraftItem(
            sectionTitle: item.sectionTitle ?? 'General',
            category: item.category,
            title: item.title,
            description: item.description,
            mandatory: item.mandatory,
            criticalSafetyItem: item.criticalSafetyItem,
            autoCreateRepair: item.autoCreateRepair,
            repairPriority: item.repairPriority,
            roadworthyImpact: item.roadworthyImpact,
            photoRequiredOnFail: item.photoRequiredOnFail,
            allowNotes: item.allowNotes,
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addItem({_TemplateDraftItem? existing, int? index}) async {
    final section = TextEditingController(
      text: existing?.sectionTitle ?? 'General',
    );
    final category = TextEditingController(
      text: existing?.category ?? 'General',
    );
    final title = TextEditingController(text: existing?.title ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    var mandatory = existing?.mandatory ?? true;
    var critical = existing?.criticalSafetyItem ?? false;
    var autoRepair = existing?.autoCreateRepair ?? true;
    var priority = existing?.repairPriority ?? 'medium';
    var roadworthyImpact = existing?.roadworthyImpact ?? 'none';
    var photoRequired = existing?.photoRequiredOnFail ?? false;
    var allowNotes = existing?.allowNotes ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Add checklist item' : 'Edit checklist item',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: section,
                  decoration: const InputDecoration(labelText: 'Section'),
                ),
                TextField(
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Check / question',
                  ),
                ),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Guidance / description',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Repair priority if failed',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                      value: 'critical',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) =>
                      setLocal(() => priority = value ?? priority),
                ),
                DropdownButtonFormField<String>(
                  initialValue: roadworthyImpact,
                  decoration: const InputDecoration(
                    labelText: 'Roadworthy impact if failed',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(
                      value: 'advisory',
                      child: Text('Advisory'),
                    ),
                    DropdownMenuItem(
                      value: 'notRoadworthy',
                      child: Text('Not roadworthy'),
                    ),
                  ],
                  onChanged: (value) => setLocal(
                    () => roadworthyImpact = value ?? roadworthyImpact,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: mandatory,
                  title: const Text('Mandatory'),
                  onChanged: (value) =>
                      setLocal(() => mandatory = value ?? true),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: critical,
                  title: const Text('Critical safety item'),
                  onChanged: (value) =>
                      setLocal(() => critical = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: autoRepair,
                  title: const Text('Create repair job from failed defect'),
                  onChanged: (value) =>
                      setLocal(() => autoRepair = value ?? true),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: photoRequired,
                  title: const Text('Photo required when failed'),
                  onChanged: (value) =>
                      setLocal(() => photoRequired = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: allowNotes,
                  title: const Text('Allow notes'),
                  onChanged: (value) =>
                      setLocal(() => allowNotes = value ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save item'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || title.text.trim().isEmpty) return;
    final draft = _TemplateDraftItem(
      sectionTitle: section.text.trim().isEmpty
          ? 'General'
          : section.text.trim(),
      category: category.text.trim().isEmpty ? 'General' : category.text.trim(),
      title: title.text.trim(),
      description: description.text.trim(),
      mandatory: mandatory,
      criticalSafetyItem: critical,
      autoCreateRepair: autoRepair,
      repairPriority: priority,
      roadworthyImpact: roadworthyImpact,
      photoRequiredOnFail: photoRequired,
      allowNotes: allowNotes,
    );
    setState(() {
      if (index == null) {
        _items.add(draft);
      } else {
        _items[index] = draft;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a template name and at least one checklist item.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.saveTemplate(
        BackendWorkshopTemplateWrite(
          id: widget.template?.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          inspectionType: _inspectionType,
          isActive: _active,
          items: [
            for (var i = 0; i < _items.length; i++)
              BackendWorkshopTemplateItemWrite(
                sectionTitle: _items[i].sectionTitle,
                category: _items[i].category,
                title: _items[i].title,
                description: _items[i].description,
                mandatory: _items[i].mandatory,
                criticalSafetyItem: _items[i].criticalSafetyItem,
                autoCreateRepair: _items[i].autoCreateRepair,
                repairPriority: _items[i].repairPriority,
                roadworthyImpact: _items[i].roadworthyImpact,
                photoRequiredOnFail: _items[i].photoRequiredOnFail,
                allowNotes: _items[i].allowNotes,
                displayOrder: i,
              ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Template save failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: widget.template == null
        ? 'Create Inspection Form'
        : 'Edit Inspection Form',
    subtitle: 'Wizard ${_step + 1} of 4',
    child: _loading
        ? const AppLoadingState(label: 'Loading template...')
        : Column(
            children: [
              LinearProgressIndicator(value: (_step + 1) / 4),
              const SizedBox(height: 16),
              Expanded(child: _stepBody()),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_step > 0)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => setState(() => _step--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                    ),
                  const Spacer(),
                  if (_step < 3)
                    FilledButton.icon(
                      onPressed: () => setState(() => _step++),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save Form'),
                    ),
                ],
              ),
            ],
          ),
  );

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return ListView(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Form name'),
            ),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _inspectionType,
              decoration: const InputDecoration(labelText: 'Inspection type'),
              items: const [
                DropdownMenuItem(
                  value: 'defectInspection',
                  child: Text('Defect inspection'),
                ),
                DropdownMenuItem(
                  value: 'scheduledService',
                  child: Text('Scheduled service'),
                ),
                DropdownMenuItem(
                  value: 'annualInspection',
                  child: Text('Annual inspection'),
                ),
                DropdownMenuItem(
                  value: 'motPreparation',
                  child: Text('MOT preparation'),
                ),
                DropdownMenuItem(
                  value: 'repairInspection',
                  child: Text('Repair inspection'),
                ),
                DropdownMenuItem(
                  value: 'returnToService',
                  child: Text('Return to service'),
                ),
                DropdownMenuItem(
                  value: 'driverDailyInspection',
                  child: Text('Driver daily inspection'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _inspectionType = value ?? _inspectionType),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              title: const Text('Form active'),
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        );
      case 1:
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sections & checklist items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty)
              const Text(
                'Add checks in the order they should appear to the user.',
              ),
            for (var i = 0; i < _items.length; i++)
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(_items[i].title),
                  subtitle: Text(
                    '${_items[i].sectionTitle} · ${_items[i].category} · ${_items[i].repairPriority}',
                  ),
                  onTap: () => _addItem(existing: _items[i], index: i),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    onPressed: () => setState(() => _items.removeAt(i)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
          ],
        );
      case 2:
        final groups = <String, List<_TemplateDraftItem>>{};
        for (final item in _items) {
          groups.putIfAbsent(item.sectionTitle, () => []).add(item);
        }
        return ListView(
          children: [
            Text('Preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _name.text.trim().isEmpty
                  ? 'Untitled inspection form'
                  : _name.text.trim(),
            ),
            for (final entry in groups.entries) ...[
              const SizedBox(height: 16),
              Text(
                entry.key,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              for (final item in entry.value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_box_outline_blank),
                  title: Text(item.title),
                  subtitle: item.description.isEmpty
                      ? null
                      : Text(item.description),
                  trailing: item.photoRequiredOnFail
                      ? const Icon(Icons.photo_camera_outlined)
                      : null,
                ),
            ],
          ],
        );
      default:
        return ListView(
          children: [
            Text(
              'Ready to save',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(
                _name.text.trim().isEmpty ? 'Untitled form' : _name.text.trim(),
              ),
              subtitle: Text(
                '${_items.length} checklist items · ${_label(_inspectionType)}',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.build_circle_outlined),
              title: Text(
                '${_items.where((item) => item.autoCreateRepair).length} items create repair jobs when failed',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: Text(
                '${_items.where((item) => item.photoRequiredOnFail).length} items require a failure photo',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'After saving, the form is immediately available from New Inspection without a manual refresh.',
            ),
          ],
        );
    }
  }

  static String _label(String value) => value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );
}

class _TemplateDraftItem {
  const _TemplateDraftItem({
    required this.sectionTitle,
    required this.category,
    required this.title,
    required this.description,
    required this.mandatory,
    required this.criticalSafetyItem,
    required this.autoCreateRepair,
    required this.repairPriority,
    required this.roadworthyImpact,
    required this.photoRequiredOnFail,
    required this.allowNotes,
  });

  final String sectionTitle;
  final String category;
  final String title;
  final String description;
  final bool mandatory;
  final bool criticalSafetyItem;
  final bool autoCreateRepair;
  final String repairPriority;
  final String roadworthyImpact;
  final bool photoRequiredOnFail;
  final bool allowNotes;
}
