import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';

/// Widget for displaying and managing collections
class CollectionList extends StatelessWidget {
  final CollectionService collectionService;
  final Function(DocumentCollection)? onCollectionSelected;
  final Function(DocumentCollection)? onCollectionDeleted;
  final VoidCallback? onCreateCollection;

  const CollectionList({
    super.key,
    required this.collectionService,
    this.onCollectionSelected,
    this.onCollectionDeleted,
    this.onCreateCollection,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: collectionService,
      builder: (context, child) {
        final collections = collectionService.collections;
        final activeCollection = collectionService.activeCollection;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              const Divider(height: 1),

              // Collection list
              Expanded(
                child: collections.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: collections.length,
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          final isActive =
                              activeCollection?.id == collection.id;

                          return _CollectionItem(
                            collection: collection,
                            isActive: isActive,
                            onTap: () {
                              collectionService
                                  .setActiveCollection(collection.id);
                              onCollectionSelected?.call(collection);
                            },
                            onEdit: () => _showEditDialog(context, collection),
                            onDelete: () =>
                                _confirmDelete(context, collection),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.collections_bookmark, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Collections',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => _showCreateDialog(context),
            tooltip: 'New Collection',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Collections',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create collections to organize\nyour documents',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Collection'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateCollectionDialog(
        onCreated: (name, colorValue) {
          collectionService.createManualCollection(name, colorValue: colorValue);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, DocumentCollection collection) {
    showDialog(
      context: context,
      builder: (context) => _EditCollectionDialog(
        collection: collection,
        onSaved: (name, colorValue) {
          collectionService.renameCollection(collection.id, name);
          collectionService.setCollectionColor(collection.id, colorValue);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentCollection collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text(
          'Are you sure you want to delete "${collection.name}"?\n\n'
          'This will not delete any documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              collectionService.deleteCollection(collection.id);
              onCollectionDeleted?.call(collection);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Widget for a single collection item
class _CollectionItem extends StatelessWidget {
  final DocumentCollection collection;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CollectionItem({
    required this.collection,
    required this.isActive,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(collection.colorValue);

    return InkWell(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          border: Border(
            left: BorderSide(
              width: 3,
              color: isActive ? color : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),

            // Collection info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          collection.name,
                          style: TextStyle(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (collection.isSmartCollection)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.amber[700],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${collection.documentCount} document${collection.documentCount != 1 ? 's' : ''} • ${collection.type.displayName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            if (collection.isSmartCollection)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Refresh'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Refresh smart collection
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating a new collection
class _CreateCollectionDialog extends StatefulWidget {
  final Function(String name, int colorValue) onCreated;

  const _CreateCollectionDialog({required this.onCreated});

  @override
  State<_CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<_CreateCollectionDialog> {
  final _nameController = TextEditingController();
  int _selectedColor = CollectionColors.blue;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'My Collection',
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Color',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CollectionColors.all.map((color) {
              final isSelected = _selectedColor == color;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(color).withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onCreated(_nameController.text, _selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Dialog for editing a collection
class _EditCollectionDialog extends StatefulWidget {
  final DocumentCollection collection;
  final Function(String name, int colorValue) onSaved;

  const _EditCollectionDialog({
    required this.collection,
    required this.onSaved,
  });

  @override
  State<_EditCollectionDialog> createState() => _EditCollectionDialogState();
}

class _EditCollectionDialogState extends State<_EditCollectionDialog> {
  late final TextEditingController _nameController;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collection.name);
    _selectedColor = widget.collection.colorValue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Color',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CollectionColors.all.map((color) {
              final isSelected = _selectedColor == color;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(color).withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSaved(_nameController.text, _selectedColor);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Compact collection selector for use in toolbars
class CollectionSelector extends StatelessWidget {
  final CollectionService collectionService;
  final Function(DocumentCollection?)? onChanged;

  const CollectionSelector({
    super.key,
    required this.collectionService,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: collectionService,
      builder: (context, child) {
        final collections = collectionService.collections;
        final activeCollection = collectionService.activeCollection;

        return PopupMenuButton<String?>(
          initialValue: activeCollection?.id,
          onSelected: (id) {
            collectionService.setActiveCollection(id);
            if (id != null) {
              final collection = collectionService.getCollection(id);
              onChanged?.call(collection);
            } else {
              onChanged?.call(null);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.folder_open, size: 18),
                  SizedBox(width: 8),
                  Text('All Documents'),
                ],
              ),
            ),
            if (collections.isNotEmpty) const PopupMenuDivider(),
            ...collections.map((collection) {
              return PopupMenuItem(
                value: collection.id,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(collection.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        collection.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${collection.documentCount}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activeCollection != null)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Color(activeCollection.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  activeCollection?.name ?? 'All Documents',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
