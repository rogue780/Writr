import 'package:flutter/material.dart';
import '../models/scrivener_project.dart';

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
              color: Theme.of(context).colorScheme.surfaceVariant,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: const Text(
              'Binder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
