import 'package:flutter/material.dart';

import '../../../shared/status_badge.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../auth/services/permission_service.dart';
import '../models/inspection_item.dart';
import '../models/inspection_template.dart';
import '../models/inspection_template_item.dart';
import '../models/inspection_template_section.dart';
import '../models/repair_job.dart';
import '../repositories/inspection_template_repository.dart';

class InspectionTemplatesScreen extends StatefulWidget {
  const InspectionTemplatesScreen({super.key});

  @override
  State<InspectionTemplatesScreen> createState() =>
      _InspectionTemplatesScreenState();
}

class _InspectionTemplatesScreenState extends State<InspectionTemplatesScreen> {
  final InspectionTemplateRepository _repository = InspectionTemplateRepository();
  late Future<List<_TemplateSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadTemplates();
  }

  Future<List<_TemplateSummary>> _loadTemplates() async {
    final templates = await _repository.getTemplates();
    final summaries = <_TemplateSummary>[];
    for (final template in templates) {
      final templateId = template.id;
      if (templateId == null) continue;
      final results = await Future.wait([
        _repository.getTemplateSections(templateId),
        _repository.getTemplateItems(templateId),
      ]);
      summaries.add(_TemplateSummary(
        template: template,
        sectionCount: (results[0] as List<InspectionTemplateSection>).length,
        itemCount: (results[1] as List<InspectionTemplateItem>).length,
      ));
    }
    return summaries;
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadTemplates());
    await _future;
  }

  Future<void> _openBuilder({InspectionTemplate? template, bool duplicate = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InspectionTemplateBuilderScreen(
          template: template,
          duplicate: duplicate,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Future<void> _toggleActive(InspectionTemplate template) async {
    await _repository.updateTemplate(
      template.copyWith(isActive: !template.isActive, updatedAt: DateTime.now()),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageInspectionTemplates) {
      return const _TemplateAccessDenied();
    }

    return AppPageScaffold(
      title: 'Inspection Templates',
      subtitle: 'Create and manage reusable inspection forms.',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        icon: const Icon(Icons.add),
        label: const Text('Create Template'),
      ),
      child: FutureBuilder<List<_TemplateSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(label: 'Loading inspection templates...');
          }
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Unable to load templates.\n${snapshot.error}',
              onRetry: _refresh,
            );
          }
          final templates = snapshot.data ?? const <_TemplateSummary>[];
          if (templates.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 96),
                  AppEmptyState(
                    icon: Icons.article_outlined,
                    title: 'No custom inspection templates',
                    message: 'Create a reusable form to tailor workshop inspections.',
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final summary = templates[index];
                final template = summary.template;
                return SectionCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(template.isActive ? Icons.article_outlined : Icons.archive_outlined),
                    ),
                    title: Text(template.name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${template.vehicleType.name} • ${summary.sectionCount} sections • '
                            '${summary.itemCount} items',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              template.isActive
                                  ? StatusBadge.success('Active')
                                  : StatusBadge.warning('Archived'),
                              Text('Updated ${_dateLabel(template.updatedAt)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            _openBuilder(template: template);
                            break;
                          case 'duplicate':
                            _openBuilder(template: template, duplicate: true);
                            break;
                          case 'active':
                            _toggleActive(template);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                        PopupMenuItem(
                          value: 'active',
                          child: Text(template.isActive ? 'Archive' : 'Activate'),
                        ),
                      ],
                    ),
                    onTap: () => _openBuilder(template: template),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class InspectionTemplateBuilderScreen extends StatefulWidget {
  final InspectionTemplate? template;
  final bool duplicate;

  const InspectionTemplateBuilderScreen({
    super.key,
    this.template,
    this.duplicate = false,
  });

  @override
  State<InspectionTemplateBuilderScreen> createState() =>
      _InspectionTemplateBuilderScreenState();
}

class _InspectionTemplateBuilderScreenState extends State<InspectionTemplateBuilderScreen> {
  final InspectionTemplateRepository _repository = InspectionTemplateRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<_SectionDraft> _sections = [];
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  bool _isActive = true;
  WorkshopVehicleType _vehicleType = WorkshopVehicleType.van;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final template = widget.template;
    if (template == null) {
      _loading = false;
      return;
    }
    _nameController.text = widget.duplicate ? '${template.name} Copy' : template.name;
    _descriptionController.text = template.description;
    _isActive = template.isActive;
    _vehicleType = template.vehicleType;
    final templateId = template.id;
    if (templateId != null) {
      final results = await Future.wait([
        _repository.getTemplateSections(templateId),
        _repository.getTemplateItems(templateId),
      ]);
      final sections = results[0] as List<InspectionTemplateSection>;
      final items = results[1] as List<InspectionTemplateItem>;
      for (final section in sections) {
        _sections.add(_SectionDraft(
          title: section.title,
          items: items.where((item) => item.sectionId == section.id).toList(),
        ));
      }
      final unsectioned = items.where((item) => item.sectionId == null).toList();
      if (unsectioned.isNotEmpty) {
        _sections.add(_SectionDraft(title: 'General', items: unsectioned));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addSection({int? editIndex}) async {
    final controller = TextEditingController(text: editIndex == null ? '' : _sections[editIndex].title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editIndex == null ? 'Add Section' : 'Rename Section'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Section title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty) return;
    setState(() {
      if (editIndex == null) {
        _sections.add(_SectionDraft(title: title));
      } else {
        _sections[editIndex].title = title;
      }
    });
  }

  Future<void> _editItem(int sectionIndex, {int? itemIndex}) async {
    final initial = itemIndex == null ? null : _sections[sectionIndex].items[itemIndex];
    final item = await showDialog<InspectionTemplateItem>(
      context: context,
      builder: (_) => _TemplateItemDialog(initial: initial),
    );
    if (item == null) return;
    setState(() {
      if (itemIndex == null) {
        _sections[sectionIndex].items.add(item);
      } else {
        _sections[sectionIndex].items[itemIndex] = item;
      }
    });
  }

  void _moveSection(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _sections.length) return;
    setState(() {
      final section = _sections.removeAt(index);
      _sections.insert(target, section);
    });
  }

  void _moveItem(int sectionIndex, int itemIndex, int offset) {
    final items = _sections[sectionIndex].items;
    final target = itemIndex + offset;
    if (target < 0 || target >= items.length) return;
    setState(() {
      final item = items.removeAt(itemIndex);
      items.insert(target, item);
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a form name and at least one section.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final original = widget.template;
      final template = InspectionTemplate(
        id: widget.duplicate ? null : original?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        vehicleType: _vehicleType,
        isDefault: false,
        isActive: _isActive,
        createdAt: widget.duplicate || original == null ? now : original.createdAt,
        updatedAt: now,
      );
      late final int templateId;
      if (template.id == null) {
        templateId = await _repository.createTemplate(template);
      } else {
        await _repository.updateTemplate(template);
        templateId = template.id!;
      }
      final sections = List.generate(
        _sections.length,
        (index) => InspectionTemplateSection(
          templateId: templateId,
          title: _sections[index].title,
          displayOrder: index,
        ),
      );
      await _repository.replaceTemplateContent(
        templateId: templateId,
        sections: sections,
        sectionItems: _sections.map((section) => section.items).toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canManageInspectionTemplates) {
      return const _TemplateAccessDenied();
    }
    final isNewTemplate = widget.template == null || widget.duplicate;
    final title = isNewTemplate
        ? 'Create Inspection Template'
        : 'Edit Inspection Template';

    if (_loading) {
      return AppPageScaffold(
        title: title,
        child: const AppLoadingState(label: 'Loading template...'),
      );
    }

    return AppPageScaffold(
      title: title,
      subtitle: 'Build a reusable inspection form in six steps.',
      child: Stepper(
        currentStep: _step,
        onStepTapped: (value) => setState(() => _step = value),
        onStepContinue: () {
          if (_step == 5) {
            _save();
          } else {
            setState(() => _step++);
          }
        },
        onStepCancel: _step == 0 ? () => Navigator.of(context).pop() : () => setState(() => _step--),
        controlsBuilder: (context, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Wrap(spacing: 12, children: [
            FilledButton(onPressed: _saving ? null : details.onStepContinue, child: Text(_step == 5 ? 'Save Template' : 'Continue')),
            TextButton(onPressed: details.onStepCancel, child: Text(_step == 0 ? 'Cancel' : 'Back')),
          ]),
        ),
        steps: [
          Step(title: const Text('Form Details'), content: _buildDetails(), isActive: _step >= 0),
          Step(title: const Text('Sections'), content: _buildSections(), isActive: _step >= 1),
          Step(title: const Text('Items'), content: _buildItems(), isActive: _step >= 2),
          Step(title: const Text('Defect / Repair Rules'), content: _buildRules(), isActive: _step >= 3),
          Step(title: const Text('Preview'), content: _buildPreview(), isActive: _step >= 4),
          Step(title: const Text('Save'), content: const Text('Save this reusable template. Existing completed inspections retain their saved item snapshots.'), isActive: _step >= 5),
        ],
      ),
    );
  }

  Widget _buildDetails() => SectionCard(
    child: Column(children: [
      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Form name')),
      const SizedBox(height: 12),
      TextField(controller: _descriptionController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
      const SizedBox(height: 12),
      DropdownButtonFormField<WorkshopVehicleType>(initialValue: _vehicleType, decoration: const InputDecoration(labelText: 'Vehicle category'), items: WorkshopVehicleType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(), onChanged: (value) { if (value != null) setState(() => _vehicleType = value); }),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: _isActive, onChanged: (value) => setState(() => _isActive = value)),
    ]),
  );

  Widget _buildSections() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addSection,
            icon: const Icon(Icons.add),
            label: const Text('Add Section'),
          ),
        ),
        for (var index = 0; index < _sections.length; index++)
          ListTile(
            title: Text(_sections[index].title),
            subtitle: Text('${_sections[index].items.length} items'),
            trailing: Wrap(
              spacing: 0,
              children: [
                IconButton(
                  onPressed:
                      index == 0 ? null : () => _moveSection(index, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  onPressed: index == _sections.length - 1
                      ? null
                      : () => _moveSection(index, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  onPressed: () => _addSection(editIndex: index),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => setState(() => _sections.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItems() {
    return Column(
      children: [
        if (_sections.isEmpty)
          const Text('Add sections before adding items.'),
        for (var sectionIndex = 0;
            sectionIndex < _sections.length;
            sectionIndex++)
          SectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _sections[sectionIndex].title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _editItem(sectionIndex),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  for (var itemIndex = 0;
                      itemIndex < _sections[sectionIndex].items.length;
                      itemIndex++)
                    ListTile(
                      title: Text(_sections[sectionIndex].items[itemIndex].title),
                      subtitle: Text(
                        _sections[sectionIndex].items[itemIndex].responseType.name,
                      ),
                      trailing: Wrap(
                        spacing: 0,
                        children: [
                          IconButton(
                            onPressed: itemIndex == 0
                                ? null
                                : () => _moveItem(sectionIndex, itemIndex, -1),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            onPressed: itemIndex ==
                                    _sections[sectionIndex].items.length - 1
                                ? null
                                : () => _moveItem(sectionIndex, itemIndex, 1),
                            icon: const Icon(Icons.arrow_downward),
                          ),
                          IconButton(
                            onPressed: () => _editItem(
                              sectionIndex,
                              itemIndex: itemIndex,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => setState(
                              () => _sections[sectionIndex].items.removeAt(itemIndex),
                            ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ),
      ],
    );
  }

  Widget _buildRules() {
    return Column(
      children: [
        for (final section in _sections)
          for (var index = 0; index < section.items.length; index++)
            _RuleEditor(
              item: section.items[index],
              onChanged: (item) => setState(() => section.items[index] = item),
            ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nameController.text.isEmpty ? 'Untitled form' : _nameController.text,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final section in _sections)
          SectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final item in section.items)
                    ListTile(
                      title: Text(item.title),
                      subtitle: Text(
                        item.description.isEmpty
                            ? item.responseType.name
                            : item.description,
                      ),
                    ),
                ],
              ),
          ),
      ],
    );
  }
}

class _TemplateItemDialog extends StatefulWidget {
  final InspectionTemplateItem? initial;
  const _TemplateItemDialog({this.initial});
  @override
  State<_TemplateItemDialog> createState() => _TemplateItemDialogState();
}

class _TemplateItemDialogState extends State<_TemplateItemDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late InspectionResponseType _responseType;
  late bool _required;
  late bool _notes;
  late bool _photo;
  late bool _repair;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _description = TextEditingController(text: widget.initial?.description ?? '');
    _responseType = widget.initial?.responseType ??
        InspectionResponseType.passFailNotApplicable;
    _required = widget.initial?.mandatory ?? true;
    _notes = widget.initial?.allowNotes ?? true;
    _photo = widget.initial?.photoRequiredOnFail ?? false;
    _repair = widget.initial?.autoCreateRepair ?? true;
  }
  @override void dispose() { _title.dispose(); _description.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add Item' : 'Edit Item'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Item title')),
      TextField(controller: _description, decoration: const InputDecoration(labelText: 'Help text')),
      DropdownButtonFormField<InspectionResponseType>(initialValue: _responseType, decoration: const InputDecoration(labelText: 'Response type'), items: InspectionResponseType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(), onChanged: (value) { if (value != null) setState(() => _responseType = value); }),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Required'), value: _required, onChanged: (value) => setState(() => _required = value)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Allow notes'), value: _notes, onChanged: (value) => setState(() => _notes = value)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Photo required on fail'), value: _photo, onChanged: (value) => setState(() => _photo = value)),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Create repair on fail'), value: _repair, onChanged: (value) => setState(() => _repair = value)),
    ])),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (_title.text.trim().isEmpty) return; Navigator.pop(context, InspectionTemplateItem(templateId: 0, category: InspectionCategory.vehicleInformation, title: _title.text.trim(), description: _description.text.trim(), displayOrder: 0, mandatory: _required, allowNotes: _notes, photoRequiredOnFail: _photo, autoCreateRepair: _repair, responseType: _responseType)); }, child: const Text('Save'))],
  );
}

class _RuleEditor extends StatelessWidget {
  final InspectionTemplateItem item;
  final ValueChanged<InspectionTemplateItem> onChanged;
  const _RuleEditor({required this.item, required this.onChanged});
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(item.title, style: Theme.of(context).textTheme.titleSmall),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Create repair when failed'), value: item.autoCreateRepair, onChanged: (value) => onChanged(item.copyWith(autoCreateRepair: value))),
    if (item.autoCreateRepair) DropdownButtonFormField<RepairPriority>(initialValue: item.repairPriority, decoration: const InputDecoration(labelText: 'Default repair priority'), items: RepairPriority.values.map((priority) => DropdownMenuItem(value: priority, child: Text(priority.name))).toList(), onChanged: (value) { if (value != null) onChanged(item.copyWith(repairPriority: value)); }),
    DropdownButtonFormField<TemplateRoadworthyImpact>(initialValue: item.roadworthyImpact, decoration: const InputDecoration(labelText: 'Roadworthy impact'), items: TemplateRoadworthyImpact.values.map((impact) => DropdownMenuItem(value: impact, child: Text(impact.name))).toList(), onChanged: (value) { if (value != null) onChanged(item.copyWith(roadworthyImpact: value)); }),
  ])));
}

class _SectionDraft {
  String title;
  final List<InspectionTemplateItem> items;
  _SectionDraft({required this.title, List<InspectionTemplateItem>? items}) : items = items ?? [];
}

class _TemplateSummary {
  final InspectionTemplate template;
  final int sectionCount;
  final int itemCount;
  const _TemplateSummary({required this.template, required this.sectionCount, required this.itemCount});
}

class _TemplateAccessDenied extends StatelessWidget {
  const _TemplateAccessDenied();
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Access Denied')),
    body: const Center(child: Text('You do not have permission to manage inspection templates.')),
  );
}
