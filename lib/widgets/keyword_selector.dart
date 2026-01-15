import 'package:flutter/material.dart';
import '../models/keyword.dart';
import '../services/keyword_service.dart';

/// Widget for selecting keywords for a document
class KeywordSelector extends StatefulWidget {
  final KeywordService keywordService;
  final String documentId;
  final Function(List<Keyword>)? onChanged;

  const KeywordSelector({
    super.key,
    required this.keywordService,
    required this.documentId,
    this.onChanged,
  });

  @override
  State<KeywordSelector> createState() => _KeywordSelectorState();
}

class _KeywordSelectorState extends State<KeywordSelector> {
  @override
  Widget build(BuildContext context) {
    final selectedKeywords = widget.keywordService.getKeywordsForDocument(
      widget.documentId,
    );
    final allKeywords = widget.keywordService.keywords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected keywords chips
        if (selectedKeywords.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: selectedKeywords.map((keyword) {
              return Chip(
                label: Text(
                  keyword.name,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: keyword.color.withValues(alpha: 0.3),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  widget.keywordService.removeKeywordFromDocument(
                    widget.documentId,
                    keyword.id,
                  );
                  setState(() {});
                  widget.onChanged?.call(
                    widget.keywordService.getKeywordsForDocument(widget.documentId),
                  );
                },
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),

        const SizedBox(height: 8),

        // Add keyword button
        OutlinedButton.icon(
          onPressed: () => _showKeywordPicker(context, allKeywords, selectedKeywords),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Keyword'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  void _showKeywordPicker(
    BuildContext context,
    List<Keyword> allKeywords,
    List<Keyword> selectedKeywords,
  ) {
    showDialog(
      context: context,
      builder: (context) => _KeywordPickerDialog(
        keywordService: widget.keywordService,
        allKeywords: allKeywords,
        selectedKeywordIds: selectedKeywords.map((k) => k.id).toSet(),
        onKeywordToggled: (keywordId, selected) {
          if (selected) {
            widget.keywordService.assignKeywordToDocument(
              widget.documentId,
              keywordId,
            );
          } else {
            widget.keywordService.removeKeywordFromDocument(
              widget.documentId,
              keywordId,
            );
          }
          setState(() {});
          widget.onChanged?.call(
            widget.keywordService.getKeywordsForDocument(widget.documentId),
          );
        },
      ),
    );
  }
}

class _KeywordPickerDialog extends StatefulWidget {
  final KeywordService keywordService;
  final List<Keyword> allKeywords;
  final Set<String> selectedKeywordIds;
  final Function(String keywordId, bool selected) onKeywordToggled;

  const _KeywordPickerDialog({
    required this.keywordService,
    required this.allKeywords,
    required this.selectedKeywordIds,
    required this.onKeywordToggled,
  });

  @override
  State<_KeywordPickerDialog> createState() => _KeywordPickerDialogState();
}

class _KeywordPickerDialogState extends State<_KeywordPickerDialog> {
  late Set<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedKeywordIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredKeywords = _searchQuery.isEmpty
        ? widget.allKeywords
        : widget.allKeywords
            .where((k) => k.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Dialog(
      child: Container(
        width: 350,
        height: 450,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.label, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Select Keywords',
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

            // Search
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search keywords...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Keywords list
            Expanded(
              child: filteredKeywords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.label_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No keywords found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredKeywords.length,
                      itemBuilder: (context, index) {
                        final keyword = filteredKeywords[index];
                        final isSelected = _selectedIds.contains(keyword.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(keyword.id);
                              } else {
                                _selectedIds.remove(keyword.id);
                              }
                            });
                            widget.onKeywordToggled(keyword.id, value ?? false);
                          },
                          title: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: keyword.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(keyword.name)),
                            ],
                          ),
                          subtitle: Text(
                            '${widget.keywordService.getKeywordUsageCount(keyword.id)} documents',
                            style: const TextStyle(fontSize: 12),
                          ),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),

            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showCreateKeywordDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Keyword'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateKeywordDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateKeywordDialog(
        keywordService: widget.keywordService,
        onCreated: (keyword) {
          setState(() {});
        },
      ),
    );
  }
}

/// Dialog for creating a new keyword
class CreateKeywordDialog extends StatefulWidget {
  final KeywordService keywordService;
  final Function(Keyword)? onCreated;

  const CreateKeywordDialog({
    super.key,
    required this.keywordService,
    this.onCreated,
  });

  @override
  State<CreateKeywordDialog> createState() => _CreateKeywordDialogState();
}

class _CreateKeywordDialogState extends State<CreateKeywordDialog> {
  final _nameController = TextEditingController();
  int _selectedColorIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Keyword'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Keyword Name',
              hintText: 'e.g., Character, Setting',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const Text('Color:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(KeywordColors.palette.length, (index) {
              final isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColorIndex = index;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: KeywordColors.palette[index],
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 2)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              final keyword = widget.keywordService.createKeyword(
                name: _nameController.text.trim(),
                colorValue: KeywordColors.getColorValue(_selectedColorIndex),
              );
              widget.onCreated?.call(keyword);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Widget for managing all keywords
class KeywordManagerScreen extends StatefulWidget {
  final KeywordService keywordService;

  const KeywordManagerScreen({
    super.key,
    required this.keywordService,
  });

  @override
  State<KeywordManagerScreen> createState() => _KeywordManagerScreenState();
}

class _KeywordManagerScreenState extends State<KeywordManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final keywords = widget.keywordService.keywords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyword Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(),
            tooltip: 'Add Keyword',
          ),
        ],
      ),
      body: keywords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.label_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No keywords yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create keywords to categorize your documents',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      widget.keywordService.createDefaultKeywords();
                      setState(() {});
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Create Default Keywords'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: keywords.length,
              itemBuilder: (context, index) {
                final keyword = keywords[index];
                final usageCount = widget.keywordService.getKeywordUsageCount(keyword.id);

                return ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: keyword.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(keyword.name),
                  subtitle: Text('Used in $usageCount documents'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(keyword);
                          break;
                        case 'delete':
                          _confirmDelete(keyword);
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
                );
              },
            ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateKeywordDialog(
        keywordService: widget.keywordService,
        onCreated: (keyword) {
          setState(() {});
        },
      ),
    );
  }

  void _showEditDialog(Keyword keyword) {
    final nameController = TextEditingController(text: keyword.name);
    var selectedColorIndex = KeywordColors.palette.indexWhere(
      (c) => c.toARGB32() == keyword.colorValue,
    );
    if (selectedColorIndex < 0) selectedColorIndex = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Keyword'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Keyword Name',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(KeywordColors.palette.length, (index) {
                  final isSelected = selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        selectedColorIndex = index;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: KeywordColors.palette[index],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  widget.keywordService.updateKeyword(
                    keyword.copyWith(
                      name: nameController.text.trim(),
                      colorValue: KeywordColors.getColorValue(selectedColorIndex),
                    ),
                  );
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Keyword keyword) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Keyword'),
        content: Text(
          'Are you sure you want to delete "${keyword.name}"? '
          'It will be removed from all documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.keywordService.deleteKeyword(keyword.id);
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
