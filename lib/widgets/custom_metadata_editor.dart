import 'package:flutter/material.dart';
import '../models/custom_field.dart';
import '../services/custom_metadata_service.dart';

/// Widget for editing custom metadata on a document
class CustomMetadataEditor extends StatefulWidget {
  final CustomMetadataService metadataService;
  final String documentId;
  final Function()? onChanged;

  const CustomMetadataEditor({
    super.key,
    required this.metadataService,
    required this.documentId,
    this.onChanged,
  });

  @override
  State<CustomMetadataEditor> createState() => _CustomMetadataEditorState();
}

class _CustomMetadataEditorState extends State<CustomMetadataEditor> {
  @override
  Widget build(BuildContext context) {
    final definitions = widget.metadataService.definitions;

    if (definitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No custom fields',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showFieldManager(),
              child: const Text('Add Fields'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...definitions.map((definition) => _buildFieldEditor(definition)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _showFieldManager(),
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('Manage Fields'),
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldEditor(CustomFieldDefinition definition) {
    final value = widget.metadataService.getFieldValue(
      widget.documentId,
      definition.id,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(definition.type.icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                definition.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              if (definition.isRequired)
                const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          _buildFieldInput(definition, value),
        ],
      ),
    );
  }

  Widget _buildFieldInput(CustomFieldDefinition definition, CustomFieldValue? value) {
    switch (definition.type) {
      case CustomFieldType.text:
        return _TextFieldInput(
          value: value?.asString ?? '',
          onChanged: (newValue) => _updateValue(definition.id, newValue),
        );

      case CustomFieldType.number:
        return _NumberFieldInput(
          value: value?.asNumber,
          onChanged: (newValue) => _updateValue(definition.id, newValue),
        );

      case CustomFieldType.date:
        return _DateFieldInput(
          value: value?.asDate,
          onChanged: (newValue) => _updateValue(definition.id, newValue?.toIso8601String()),
        );

      case CustomFieldType.checkbox:
        return _CheckboxFieldInput(
          value: value?.asBool ?? false,
          onChanged: (newValue) => _updateValue(definition.id, newValue),
        );

      case CustomFieldType.dropdown:
        return _DropdownFieldInput(
          value: value?.asString,
          options: definition.options ?? [],
          onChanged: (newValue) => _updateValue(definition.id, newValue),
        );

      case CustomFieldType.multiSelect:
        return _MultiSelectFieldInput(
          values: value?.asStringList ?? [],
          options: definition.options ?? [],
          onChanged: (newValues) => _updateValue(definition.id, newValues),
        );
    }
  }

  void _updateValue(String fieldId, dynamic value) {
    widget.metadataService.setFieldValue(widget.documentId, fieldId, value);
    widget.onChanged?.call();
    setState(() {});
  }

  void _showFieldManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomFieldManagerScreen(
          metadataService: widget.metadataService,
        ),
      ),
    ).then((_) => setState(() {}));
  }
}

class _TextFieldInput extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _TextFieldInput({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: const TextStyle(fontSize: 13),
      onChanged: onChanged,
    );
  }
}

class _NumberFieldInput extends StatelessWidget {
  final num? value;
  final Function(num?) onChanged;

  const _NumberFieldInput({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value?.toString() ?? ''),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: const TextStyle(fontSize: 13),
      keyboardType: TextInputType.number,
      onChanged: (text) {
        final parsed = num.tryParse(text);
        onChanged(parsed);
      },
    );
  }
}

class _DateFieldInput extends StatelessWidget {
  final DateTime? value;
  final Function(DateTime?) onChanged;

  const _DateFieldInput({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null
                    ? '${value!.month}/${value!.day}/${value!.year}'
                    : 'Select date...',
                style: TextStyle(
                  fontSize: 13,
                  color: value != null ? null : Colors.grey,
                ),
              ),
            ),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CheckboxFieldInput extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const _CheckboxFieldInput({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (newValue) => onChanged(newValue ?? false),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          value ? 'Yes' : 'No',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

class _DropdownFieldInput extends StatelessWidget {
  final String? value;
  final List<String> options;
  final Function(String?) onChanged;

  const _DropdownFieldInput({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(value) ? value : null,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _MultiSelectFieldInput extends StatelessWidget {
  final List<String> values;
  final List<String> options;
  final Function(List<String>) onChanged;

  const _MultiSelectFieldInput({
    required this.values,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: values.map((v) {
            return Chip(
              label: Text(v, style: const TextStyle(fontSize: 11)),
              onDeleted: () {
                onChanged(values.where((x) => x != v).toList());
              },
              deleteIconColor: Colors.grey,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        PopupMenuButton<String>(
          onSelected: (option) {
            if (!values.contains(option)) {
              onChanged([...values, option]);
            }
          },
          itemBuilder: (context) => options
              .where((o) => !values.contains(o))
              .map((option) => PopupMenuItem(
                    value: option,
                    child: Text(option),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16),
                SizedBox(width: 4),
                Text('Add', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Screen for managing custom field definitions
class CustomFieldManagerScreen extends StatefulWidget {
  final CustomMetadataService metadataService;

  const CustomFieldManagerScreen({
    super.key,
    required this.metadataService,
  });

  @override
  State<CustomFieldManagerScreen> createState() => _CustomFieldManagerScreenState();
}

class _CustomFieldManagerScreenState extends State<CustomFieldManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final definitions = widget.metadataService.definitions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Fields'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(),
            tooltip: 'Add Field',
          ),
        ],
      ),
      body: definitions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_customize, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No custom fields yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create fields to add custom metadata to documents',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      widget.metadataService.createDefaultFields();
                      setState(() {});
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Create Default Fields'),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              itemCount: definitions.length,
              onReorder: (oldIndex, newIndex) {
                widget.metadataService.reorderFields(oldIndex, newIndex);
                setState(() {});
              },
              itemBuilder: (context, index) {
                final definition = definitions[index];
                return ListTile(
                  key: ValueKey(definition.id),
                  leading: Icon(definition.type.icon),
                  title: Text(definition.name),
                  subtitle: Text(definition.type.displayName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (definition.isRequired)
                        const Chip(
                          label: Text('Required', style: TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showEditDialog(definition);
                              break;
                            case 'delete':
                              _confirmDelete(definition);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _FieldEditDialog(
        onSave: (name, type, description, isRequired, options) {
          widget.metadataService.createField(
            name: name,
            type: type,
            description: description,
            isRequired: isRequired,
            options: options,
          );
          setState(() {});
        },
      ),
    );
  }

  void _showEditDialog(CustomFieldDefinition definition) {
    showDialog(
      context: context,
      builder: (context) => _FieldEditDialog(
        initialName: definition.name,
        initialType: definition.type,
        initialDescription: definition.description,
        initialRequired: definition.isRequired,
        initialOptions: definition.options,
        onSave: (name, type, description, isRequired, options) {
          widget.metadataService.updateField(
            definition.copyWith(
              name: name,
              type: type,
              description: description,
              isRequired: isRequired,
              options: options,
            ),
          );
          setState(() {});
        },
      ),
    );
  }

  void _confirmDelete(CustomFieldDefinition definition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Field'),
        content: Text(
          'Are you sure you want to delete "${definition.name}"? '
          'All values for this field will be removed from documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.metadataService.deleteField(definition.id);
              setState(() {});
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FieldEditDialog extends StatefulWidget {
  final String? initialName;
  final CustomFieldType? initialType;
  final String? initialDescription;
  final bool? initialRequired;
  final List<String>? initialOptions;
  final Function(
    String name,
    CustomFieldType type,
    String? description,
    bool isRequired,
    List<String>? options,
  ) onSave;

  const _FieldEditDialog({
    this.initialName,
    this.initialType,
    this.initialDescription,
    this.initialRequired,
    this.initialOptions,
    required this.onSave,
  });

  @override
  State<_FieldEditDialog> createState() => _FieldEditDialogState();
}

class _FieldEditDialogState extends State<_FieldEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _optionsController;
  late CustomFieldType _type;
  late bool _isRequired;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _optionsController = TextEditingController(
      text: widget.initialOptions?.join(', ') ?? '',
    );
    _type = widget.initialType ?? CustomFieldType.text;
    _isRequired = widget.initialRequired ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Field' : 'Create Field'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Field Name',
                hintText: 'e.g., POV Character',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomFieldType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Field Type',
              ),
              items: CustomFieldType.values.map((type) {
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
                    _type = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What this field is for',
              ),
            ),
            const SizedBox(height: 16),
            if (_type == CustomFieldType.dropdown || _type == CustomFieldType.multiSelect) ...[
              TextField(
                controller: _optionsController,
                decoration: const InputDecoration(
                  labelText: 'Options (comma-separated)',
                  hintText: 'Option 1, Option 2, Option 3',
                ),
              ),
              const SizedBox(height: 16),
            ],
            CheckboxListTile(
              value: _isRequired,
              onChanged: (value) {
                setState(() {
                  _isRequired = value ?? false;
                });
              },
              title: const Text('Required field'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
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
            if (_nameController.text.trim().isNotEmpty) {
              List<String>? options;
              if (_type == CustomFieldType.dropdown || _type == CustomFieldType.multiSelect) {
                options = _optionsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
              }

              widget.onSave(
                _nameController.text.trim(),
                _type,
                _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                _isRequired,
                options,
              );
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
