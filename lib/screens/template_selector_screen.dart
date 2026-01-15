import 'package:flutter/material.dart';
import '../models/template.dart';
import '../services/template_service.dart';

/// Screen for selecting project templates when creating a new project
class ProjectTemplateSelectorScreen extends StatefulWidget {
  final TemplateService templateService;
  final Function(String projectName, String templateId) onCreateProject;

  const ProjectTemplateSelectorScreen({
    super.key,
    required this.templateService,
    required this.onCreateProject,
  });

  @override
  State<ProjectTemplateSelectorScreen> createState() =>
      _ProjectTemplateSelectorScreenState();
}

class _ProjectTemplateSelectorScreenState
    extends State<ProjectTemplateSelectorScreen> {
  String? _selectedTemplateId;
  final _projectNameController = TextEditingController();
  ProjectTemplateType? _filterType;

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = _filterType == null
        ? widget.templateService.projectTemplates
        : widget.templateService.getProjectTemplatesByType(_filterType!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Project'),
      ),
      body: Column(
        children: [
          // Project name input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'Enter a name for your project',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              autofocus: true,
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterType == null,
                    onSelected: (selected) {
                      setState(() {
                        _filterType = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...ProjectTemplateType.values
                      .where((t) => t != ProjectTemplateType.custom)
                      .map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.displayName),
                        selected: _filterType == type,
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? type : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),

          // Template grid
          Expanded(
            child: templates.isEmpty
                ? Center(
                    child: Text(
                      'No templates found',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSelected = template.id == _selectedTemplateId;

                      return _ProjectTemplateCard(
                        template: template,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedTemplateId = template.id;
                          });
                        },
                      );
                    },
                  ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Create Project'),
                  onPressed: _canCreate ? _createProject : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canCreate =>
      _projectNameController.text.trim().isNotEmpty &&
      _selectedTemplateId != null;

  void _createProject() {
    final name = _projectNameController.text.trim();
    if (name.isEmpty || _selectedTemplateId == null) return;

    widget.onCreateProject(name, _selectedTemplateId!);
    Navigator.pop(context);
  }
}

/// Card widget for displaying a project template
class _ProjectTemplateCard extends StatelessWidget {
  final ProjectTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectTemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.type.icon,
                      size: 24,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (template.isBuiltIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Built-in',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.folder, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${template.folders.length} folders',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for selecting a document template
class DocumentTemplateSelectorDialog extends StatefulWidget {
  final TemplateService templateService;
  final Function(DocumentTemplate) onSelect;

  const DocumentTemplateSelectorDialog({
    super.key,
    required this.templateService,
    required this.onSelect,
  });

  @override
  State<DocumentTemplateSelectorDialog> createState() =>
      _DocumentTemplateSelectorDialogState();
}

class _DocumentTemplateSelectorDialogState
    extends State<DocumentTemplateSelectorDialog> {
  DocumentTemplateType? _filterType;
  String? _selectedTemplateId;

  @override
  Widget build(BuildContext context) {
    final templates = _filterType == null
        ? widget.templateService.documentTemplates
        : widget.templateService.getDocumentTemplatesByType(_filterType!);

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.description),
                const SizedBox(width: 8),
                const Text(
                  'Insert from Template',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterType == null,
                    onSelected: (selected) {
                      setState(() {
                        _filterType = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ...DocumentTemplateType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(type.icon, size: 16),
                        label: Text(type.displayName),
                        selected: _filterType == type,
                        onSelected: (selected) {
                          setState(() {
                            _filterType = selected ? type : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Template list
            Expanded(
              child: templates.isEmpty
                  ? Center(
                      child: Text(
                        'No templates found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        final isSelected = template.id == _selectedTemplateId;

                        return _DocumentTemplateListTile(
                          template: template,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedTemplateId = template.id;
                            });
                          },
                        );
                      },
                    ),
            ),

            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selectedTemplateId != null
                      ? () {
                          final template = widget.templateService
                              .documentTemplates
                              .firstWhere((t) => t.id == _selectedTemplateId);
                          widget.onSelect(template);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Insert'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// List tile for document templates
class _DocumentTemplateListTile extends StatelessWidget {
  final DocumentTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _DocumentTemplateListTile({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            template.icon,
            size: 20,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          template.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          template.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (template.isBuiltIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Built-in',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Dialog for creating a new document template from existing content
class CreateTemplateDialog extends StatefulWidget {
  final String initialContent;
  final Function(DocumentTemplate) onCreate;

  const CreateTemplateDialog({
    super.key,
    required this.initialContent,
    required this.onCreate,
  });

  @override
  State<CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<CreateTemplateDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DocumentTemplateType _selectedType = DocumentTemplateType.general;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Template'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., My Character Sheet',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Brief description of this template',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DocumentTemplateType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Template Type',
              ),
              items: DocumentTemplateType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
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
          onPressed: _nameController.text.trim().isNotEmpty
              ? () {
                  final template = DocumentTemplate(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text.trim(),
                    description: _descriptionController.text.trim(),
                    content: widget.initialContent,
                    type: _selectedType,
                    icon: _selectedType.icon,
                    isBuiltIn: false,
                    createdAt: DateTime.now(),
                  );
                  widget.onCreate(template);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Screen for managing templates
class TemplateManagerScreen extends StatefulWidget {
  final TemplateService templateService;

  const TemplateManagerScreen({
    super.key,
    required this.templateService,
  });

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Document Templates', icon: Icon(Icons.description)),
            Tab(text: 'Project Templates', icon: Icon(Icons.folder)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentTemplatesTab(),
          _buildProjectTemplatesTab(),
        ],
      ),
    );
  }

  Widget _buildDocumentTemplatesTab() {
    final templates = widget.templateService.documentTemplates;

    return templates.isEmpty
        ? const Center(child: Text('No document templates'))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(template.icon),
                  ),
                  title: Text(template.name),
                  subtitle: Text(template.description),
                  trailing: template.isBuiltIn
                      ? const Chip(label: Text('Built-in'))
                      : IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            widget.templateService
                                .deleteDocumentTemplate(template.id);
                            setState(() {});
                          },
                        ),
                ),
              );
            },
          );
  }

  Widget _buildProjectTemplatesTab() {
    final templates = widget.templateService.projectTemplates;

    return templates.isEmpty
        ? const Center(child: Text('No project templates'))
        : ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(template.type.icon),
                  ),
                  title: Text(template.name),
                  subtitle: Text(template.description),
                  trailing: template.isBuiltIn
                      ? const Chip(label: Text('Built-in'))
                      : IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            widget.templateService
                                .deleteProjectTemplate(template.id);
                            setState(() {});
                          },
                        ),
                ),
              );
            },
          );
  }
}
