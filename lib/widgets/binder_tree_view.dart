import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scrivener_project.dart';
import '../services/scrivener_service.dart';
import '../services/import_service.dart';

class BinderTreeView extends StatelessWidget {
  final List<BinderItem> items;
  final Function(BinderItem) onItemSelected;
  final BinderItem? selectedItem;

  const BinderTreeView({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.selectedItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Binder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add Item',
                  onSelected: (value) {
                    if (value == 'folder') {
                      _showAddDialog(context, BinderItemType.folder, null);
                    } else if (value == 'document') {
                      _showAddDialog(context, BinderItemType.text, null);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'folder',
                      child: Row(
                        children: [
                          Icon(Icons.folder, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('New Folder'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'document',
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 18, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('New Document'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: items.map((item) {
                return _BinderItemWidget(
                  item: item,
                  onItemSelected: onItemSelected,
                  selectedItem: selectedItem,
                  depth: 0,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    BinderItemType type,
    String? parentId,
  ) {
    final controller = TextEditingController();
    final typeName = type == BinderItemType.folder ? 'Folder' : 'Document';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New $typeName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: type == BinderItemType.folder ? 'Chapter 1' : 'Scene 1',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<ScrivenerService>().addBinderItem(
                      title: controller.text,
                      type: type,
                      parentId: parentId,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _BinderItemWidget extends StatefulWidget {
  final BinderItem item;
  final Function(BinderItem) onItemSelected;
  final BinderItem? selectedItem;
  final int depth;

  const _BinderItemWidget({
    required this.item,
    required this.onItemSelected,
    this.selectedItem,
    required this.depth,
  });

  @override
  State<_BinderItemWidget> createState() => _BinderItemWidgetState();
}

class _BinderItemWidgetState extends State<_BinderItemWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedItem?.id == widget.item.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => widget.onItemSelected(widget.item),
          onLongPress: () => _showContextMenu(context),
          child: Container(
            padding: EdgeInsets.only(
              left: 8.0 + (widget.depth * 16.0),
              top: 8,
              bottom: 8,
              right: 8,
            ),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: Row(
              children: [
                if (widget.item.children.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 4),
                Icon(
                  _getIconForType(widget.item.type),
                  size: 18,
                  color: _getColorForType(widget.item.type),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.item.isFolder
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && widget.item.children.isNotEmpty)
          ...widget.item.children.map((child) {
            return _BinderItemWidget(
              item: child,
              onItemSelected: widget.onItemSelected,
              selectedItem: widget.selectedItem,
              depth: widget.depth + 1,
            );
          }),
      ],
    );
  }

  void _showContextMenu(BuildContext context) {
    // Check if this is or is under the Research folder
    final isResearchFolder = widget.item.title.toLowerCase() == 'research' &&
                            widget.item.isFolder;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),
              title: const Text('Add Folder'),
              onTap: () {
                Navigator.pop(context);
                _showAddDialog(context, BinderItemType.folder, widget.item.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.grey),
              title: const Text('Add Document'),
              onTap: () {
                Navigator.pop(context);
                _showAddDialog(context, BinderItemType.text, widget.item.id);
              },
            ),
            // Show import option for Research folder or any folder
            if (widget.item.isFolder)
              ListTile(
                leading: const Icon(Icons.file_upload, color: Colors.purple),
                title: Text(isResearchFolder ? 'Import Research Files' : 'Import Files'),
                onTap: () {
                  Navigator.pop(context);
                  _importResearchFiles(context, widget.item.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importResearchFiles(BuildContext context, String parentFolderId) async {
    final importService = ImportService();
    final scrivenerService = context.read<ScrivenerService>();

    // Pick and import files
    final results = await importService.pickAndImportFiles();

    if (results.isEmpty) return;

    int successCount = 0;
    final errors = <String>[];

    for (final result in results) {
      if (result.success && result.item != null) {
        scrivenerService.addResearchItem(
          result.item!,
          parentFolderId: parentFolderId,
        );
        successCount++;
      } else if (result.error != null) {
        errors.add(result.error!);
      }
    }

    // Show result message
    if (context.mounted) {
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $successCount file${successCount > 1 ? 's' : ''} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import errors: ${errors.join(', ')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDialog(
    BuildContext context,
    BinderItemType type,
    String? parentId,
  ) {
    final controller = TextEditingController();
    final typeName = type == BinderItemType.folder ? 'Folder' : 'Document';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New $typeName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: type == BinderItemType.folder ? 'Chapter 1' : 'Scene 1',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<ScrivenerService>().addBinderItem(
                      title: controller.text,
                      type: type,
                      parentId: parentId,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.item.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<ScrivenerService>().renameBinderItem(
                      widget.item.id,
                      controller.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
          'Are you sure you want to delete "${widget.item.title}"?${widget.item.children.isNotEmpty ? '\n\nThis will also delete all items inside it.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScrivenerService>().deleteBinderItem(widget.item.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(BinderItemType type) {
    switch (type) {
      case BinderItemType.folder:
        return Icons.folder;
      case BinderItemType.text:
        return Icons.description;
      case BinderItemType.image:
        return Icons.image;
      case BinderItemType.pdf:
        return Icons.picture_as_pdf;
      case BinderItemType.webArchive:
        return Icons.web;
    }
  }

  Color _getColorForType(BinderItemType type) {
    switch (type) {
      case BinderItemType.folder:
        return Colors.blue;
      case BinderItemType.text:
        return Colors.grey;
      case BinderItemType.image:
        return Colors.green;
      case BinderItemType.pdf:
        return Colors.red;
      case BinderItemType.webArchive:
        return Colors.orange;
    }
  }
}
