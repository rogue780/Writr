import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scrivener_project.dart';
import '../services/scrivener_service.dart';
import '../services/import_service.dart';

class BinderTreeView extends StatelessWidget {
  final List<BinderItem> items;
  final Function(BinderItem) onItemSelected;
  final BinderItem? selectedItem;
  final VoidCallback? onClose;
  final ProjectMode projectMode;
  final bool isFullEditingUnlocked;

  const BinderTreeView({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.selectedItem,
    this.onClose,
    this.projectMode = ProjectMode.native,
    this.isFullEditingUnlocked = false,
  });

  /// Returns true if in Scrivener mode AND full editing is not unlocked
  bool get isScrivenerMode =>
      projectMode == ProjectMode.scrivener && !isFullEditingUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (isScrivenerMode)
                  Tooltip(
                    message: 'Disabled in Scrivener mode',
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: Theme.of(context).disabledColor,
                    ),
                  )
                else
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'Add Item',
                      padding: EdgeInsets.zero,
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
                  ),
                if (onClose != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      tooltip: 'Hide Binder',
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
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
                  projectMode: projectMode,
                  isFullEditingUnlocked: isFullEditingUnlocked,
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

    void doAdd() {
      if (controller.text.isNotEmpty) {
        try {
          context.read<ScrivenerService>().addBinderItem(
                title: controller.text,
                type: type,
                parentId: parentId,
              );
          Navigator.pop(context);
        } on StateError catch (e) {
          Navigator.pop(context);
          _showScrivenerModeError(context, e.message);
        }
      }
    }

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
          onSubmitted: (_) => doAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: doAdd,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  static void _showScrivenerModeError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Learn More',
          textColor: Colors.white,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Scrivener Mode'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This project is opened in Scrivener-compatible mode to protect your original .scriv project from corruption.',
                    ),
                    SizedBox(height: 12),
                    Text(
                      'In this mode, you can:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Edit document text'),
                    Text('• Create and restore snapshots'),
                    SizedBox(height: 12),
                    Text(
                      'To make structural changes (add/delete/rename), convert to Writr format using File → Convert to Writr Format.',
                    ),
                  ],
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BinderItemWidget extends StatefulWidget {
  final BinderItem item;
  final Function(BinderItem) onItemSelected;
  final BinderItem? selectedItem;
  final int depth;
  final ProjectMode projectMode;
  final bool isFullEditingUnlocked;

  const _BinderItemWidget({
    required this.item,
    required this.onItemSelected,
    this.selectedItem,
    required this.depth,
    this.projectMode = ProjectMode.native,
    this.isFullEditingUnlocked = false,
  });

  /// Returns true if in Scrivener mode AND full editing is not unlocked
  bool get isScrivenerMode =>
      projectMode == ProjectMode.scrivener && !isFullEditingUnlocked;

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
        GestureDetector(
          onSecondaryTapDown: (details) {
            _showPopupMenu(context, details.globalPosition);
          },
          child: InkWell(
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
        ),
        if (_isExpanded && widget.item.children.isNotEmpty)
          ...widget.item.children.map((child) {
            return _BinderItemWidget(
              item: child,
              onItemSelected: widget.onItemSelected,
              selectedItem: widget.selectedItem,
              depth: widget.depth + 1,
              projectMode: widget.projectMode,
              isFullEditingUnlocked: widget.isFullEditingUnlocked,
            );
          }),
      ],
    );
  }

  void _showContextMenu(BuildContext context) {
    // Check if this is or is under the Research folder
    final isResearchFolder = widget.item.title.toLowerCase() == 'research' &&
                            widget.item.isFolder;
    final isScrivenerMode = widget.isScrivenerMode;
    final disabledColor = Theme.of(context).disabledColor;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Scrivener mode banner
            if (isScrivenerMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.amber.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Scrivener mode: structural changes disabled',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: Icon(
                Icons.folder,
                color: isScrivenerMode ? disabledColor : Colors.blue,
              ),
              title: Text(
                'Add Folder',
                style: TextStyle(color: isScrivenerMode ? disabledColor : null),
              ),
              enabled: !isScrivenerMode,
              onTap: isScrivenerMode ? null : () {
                Navigator.pop(context);
                _showAddDialog(context, BinderItemType.folder, widget.item.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.description,
                color: isScrivenerMode ? disabledColor : Colors.grey,
              ),
              title: Text(
                'Add Document',
                style: TextStyle(color: isScrivenerMode ? disabledColor : null),
              ),
              enabled: !isScrivenerMode,
              onTap: isScrivenerMode ? null : () {
                Navigator.pop(context);
                _showAddDialog(context, BinderItemType.text, widget.item.id);
              },
            ),
            // Show import option for Research folder or any folder
            if (widget.item.isFolder)
              ListTile(
                leading: Icon(
                  Icons.file_upload,
                  color: isScrivenerMode ? disabledColor : Colors.purple,
                ),
                title: Text(
                  isResearchFolder ? 'Import Research Files' : 'Import Files',
                  style: TextStyle(color: isScrivenerMode ? disabledColor : null),
                ),
                enabled: !isScrivenerMode,
                onTap: isScrivenerMode ? null : () {
                  Navigator.pop(context);
                  _importResearchFiles(context, widget.item.id);
                },
              ),
            ListTile(
              leading: Icon(
                Icons.edit,
                color: isScrivenerMode ? disabledColor : null,
              ),
              title: Text(
                'Rename',
                style: TextStyle(color: isScrivenerMode ? disabledColor : null),
              ),
              enabled: !isScrivenerMode,
              onTap: isScrivenerMode ? null : () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: isScrivenerMode ? disabledColor : Colors.red,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: isScrivenerMode ? disabledColor : null),
              ),
              enabled: !isScrivenerMode,
              onTap: isScrivenerMode ? null : () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show popup menu at the given position (for right-click on desktop).
  void _showPopupMenu(BuildContext context, Offset position) {
    final isScrivenerMode = widget.isScrivenerMode;
    final isFolder = widget.item.isFolder;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (isFolder) ...[
          PopupMenuItem<String>(
            value: 'add_folder',
            enabled: !isScrivenerMode,
            child: Row(
              children: [
                Icon(Icons.folder, size: 18, color: isScrivenerMode ? Theme.of(context).disabledColor : Colors.blue),
                const SizedBox(width: 8),
                Text('New Folder', style: TextStyle(color: isScrivenerMode ? Theme.of(context).disabledColor : null)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'add_document',
            enabled: !isScrivenerMode,
            child: Row(
              children: [
                Icon(Icons.description, size: 18, color: isScrivenerMode ? Theme.of(context).disabledColor : Colors.grey),
                const SizedBox(width: 8),
                Text('New Document', style: TextStyle(color: isScrivenerMode ? Theme.of(context).disabledColor : null)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'import',
            enabled: !isScrivenerMode,
            child: Row(
              children: [
                Icon(Icons.file_upload, size: 18, color: isScrivenerMode ? Theme.of(context).disabledColor : Colors.purple),
                const SizedBox(width: 8),
                Text('Import Files', style: TextStyle(color: isScrivenerMode ? Theme.of(context).disabledColor : null)),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        PopupMenuItem<String>(
          value: 'rename',
          enabled: !isScrivenerMode,
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: isScrivenerMode ? Theme.of(context).disabledColor : null),
              const SizedBox(width: 8),
              Text('Rename', style: TextStyle(color: isScrivenerMode ? Theme.of(context).disabledColor : null)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          enabled: !isScrivenerMode,
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: isScrivenerMode ? Theme.of(context).disabledColor : Colors.red),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: isScrivenerMode ? Theme.of(context).disabledColor : null)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null || !context.mounted) return;
      switch (value) {
        case 'add_folder':
          _showAddDialog(context, BinderItemType.folder, widget.item.id);
          break;
        case 'add_document':
          _showAddDialog(context, BinderItemType.text, widget.item.id);
          break;
        case 'import':
          _importResearchFiles(context, widget.item.id);
          break;
        case 'rename':
          _showRenameDialog(context);
          break;
        case 'delete':
          _showDeleteDialog(context);
          break;
      }
    });
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

    void doAdd() {
      if (controller.text.isNotEmpty) {
        try {
          context.read<ScrivenerService>().addBinderItem(
                title: controller.text,
                type: type,
                parentId: parentId,
              );
          Navigator.pop(context);
        } on StateError catch (e) {
          Navigator.pop(context);
          BinderTreeView._showScrivenerModeError(context, e.message);
        }
      }
    }

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
          onSubmitted: (_) => doAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: doAdd,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.item.title);

    void doRename() {
      if (controller.text.isNotEmpty) {
        try {
          context.read<ScrivenerService>().renameBinderItem(
                widget.item.id,
                controller.text,
              );
          Navigator.pop(context);
        } on StateError catch (e) {
          Navigator.pop(context);
          BinderTreeView._showScrivenerModeError(context, e.message);
        }
      }
    }

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
          onSubmitted: (_) => doRename(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: doRename,
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
              try {
                context.read<ScrivenerService>().deleteBinderItem(widget.item.id);
                Navigator.pop(context);
              } on StateError catch (e) {
                Navigator.pop(context);
                BinderTreeView._showScrivenerModeError(context, e.message);
              }
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
    Color baseColor;
    switch (type) {
      case BinderItemType.folder:
        baseColor = Colors.blue;
        break;
      case BinderItemType.text:
        baseColor = Colors.grey;
        break;
      case BinderItemType.image:
        baseColor = Colors.green;
        break;
      case BinderItemType.pdf:
        baseColor = Colors.red;
        break;
      case BinderItemType.webArchive:
        baseColor = Colors.orange;
        break;
    }

    // Desaturate colors in Scrivener mode
    if (widget.isScrivenerMode) {
      final hsl = HSLColor.fromColor(baseColor);
      return hsl.withSaturation(hsl.saturation * 0.3).toColor();
    }

    return baseColor;
  }
}
