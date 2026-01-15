import 'package:flutter/material.dart';
import '../models/scrivener_project.dart';
import '../models/document_metadata.dart';

/// Column configuration for the outliner view.
enum OutlinerColumn {
  title('Title', 200),
  synopsis('Synopsis', 250),
  status('Status', 100),
  label('Label', 80),
  wordCount('Words', 70),
  modified('Modified', 120);

  final String header;
  final double defaultWidth;
  const OutlinerColumn(this.header, this.defaultWidth);
}

/// Outliner view displaying documents in a spreadsheet-like table.
class OutlinerView extends StatefulWidget {
  final BinderItem folder;
  final Map<String, String> textContents;
  final Map<String, DocumentMetadata> metadata;
  final BinderItem? selectedItem;
  final Function(BinderItem) onItemSelected;
  final Function(BinderItem) onItemDoubleClicked;
  final Function(String, DocumentMetadata) onMetadataChanged;

  const OutlinerView({
    super.key,
    required this.folder,
    required this.textContents,
    required this.metadata,
    this.selectedItem,
    required this.onItemSelected,
    required this.onItemDoubleClicked,
    required this.onMetadataChanged,
  });

  @override
  State<OutlinerView> createState() => _OutlinerViewState();
}

class _OutlinerViewState extends State<OutlinerView> {
  final Set<OutlinerColumn> _visibleColumns = {
    OutlinerColumn.title,
    OutlinerColumn.synopsis,
    OutlinerColumn.status,
    OutlinerColumn.label,
    OutlinerColumn.wordCount,
  };

  OutlinerColumn? _sortColumn = OutlinerColumn.title;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        Expanded(
          child: widget.folder.children.isEmpty
              ? _buildEmptyState(context)
              : _buildTable(context),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.folder, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            widget.folder.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '(${widget.folder.children.length} items)',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Spacer(),
          // Column visibility menu
          PopupMenuButton<OutlinerColumn>(
            tooltip: 'Show/Hide Columns',
            icon: const Icon(Icons.view_column, size: 20),
            onSelected: (column) {
              setState(() {
                if (_visibleColumns.contains(column)) {
                  // Don't allow hiding title
                  if (column != OutlinerColumn.title) {
                    _visibleColumns.remove(column);
                  }
                } else {
                  _visibleColumns.add(column);
                }
              });
            },
            itemBuilder: (context) {
              return OutlinerColumn.values.map((column) {
                return CheckedPopupMenuItem(
                  value: column,
                  checked: _visibleColumns.contains(column),
                  enabled: column != OutlinerColumn.title,
                  child: Text(column.header),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No documents in this folder',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final items = _getSortedItems();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortColumnIndex: _visibleColumns.toList().indexOf(_sortColumn!),
          sortAscending: _sortAscending,
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          columns: _buildColumns(),
          rows: _buildRows(items),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return _visibleColumns.map((column) {
      return DataColumn(
        label: Text(
          column.header,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortColumn = column;
            _sortAscending = ascending;
          });
        },
      );
    }).toList();
  }

  List<DataRow> _buildRows(List<BinderItem> items) {
    return items.map((item) {
      final itemMetadata = widget.metadata[item.id];
      final content = widget.textContents[item.id] ?? '';
      final isSelected = widget.selectedItem?.id == item.id;

      return DataRow(
        selected: isSelected,
        onSelectChanged: (_) => widget.onItemSelected(item),
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.primaryContainer;
          }
          return null;
        }),
        cells: _visibleColumns.map((column) {
          return DataCell(
            _buildCellContent(column, item, itemMetadata, content),
            onTap: () => widget.onItemSelected(item),
            onDoubleTap: () => widget.onItemDoubleClicked(item),
          );
        }).toList(),
      );
    }).toList();
  }

  Widget _buildCellContent(
    OutlinerColumn column,
    BinderItem item,
    DocumentMetadata? metadata,
    String content,
  ) {
    switch (column) {
      case OutlinerColumn.title:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isFolder ? Icons.folder : Icons.description,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(item.title),
          ],
        );

      case OutlinerColumn.synopsis:
        return SizedBox(
          width: column.defaultWidth,
          child: Text(
            metadata?.synopsis ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: metadata?.synopsis.isNotEmpty == true
                  ? null
                  : Colors.grey[400],
            ),
          ),
        );

      case OutlinerColumn.status:
        return Text(
          metadata?.status.displayName ?? '-',
          style: TextStyle(
            fontSize: 13,
            color: metadata?.status != DocumentStatus.noStatus
                ? null
                : Colors.grey[400],
          ),
        );

      case OutlinerColumn.label:
        if (metadata?.label != null) {
          return Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: Color(metadata!.label!.colorValue),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                metadata.label!.name,
                style: TextStyle(
                  fontSize: 11,
                  color: _contrastColor(Color(metadata.label!.colorValue)),
                ),
              ),
            ),
          );
        }
        return Text('-', style: TextStyle(color: Colors.grey[400]));

      case OutlinerColumn.wordCount:
        final wordCount = _countWords(content);
        return Text(
          wordCount.toString(),
          style: const TextStyle(fontSize: 13),
        );

      case OutlinerColumn.modified:
        if (metadata?.modifiedAt != null) {
          return Text(
            _formatDate(metadata!.modifiedAt),
            style: const TextStyle(fontSize: 12),
          );
        }
        return Text('-', style: TextStyle(color: Colors.grey[400]));
    }
  }

  List<BinderItem> _getSortedItems() {
    final items = List<BinderItem>.from(widget.folder.children);

    items.sort((a, b) {
      int comparison;
      final metaA = widget.metadata[a.id];
      final metaB = widget.metadata[b.id];

      switch (_sortColumn) {
        case OutlinerColumn.title:
          comparison = a.title.compareTo(b.title);
          break;
        case OutlinerColumn.synopsis:
          comparison = (metaA?.synopsis ?? '').compareTo(metaB?.synopsis ?? '');
          break;
        case OutlinerColumn.status:
          comparison = (metaA?.status.index ?? 0).compareTo(metaB?.status.index ?? 0);
          break;
        case OutlinerColumn.label:
          comparison = (metaA?.label?.name ?? '').compareTo(metaB?.label?.name ?? '');
          break;
        case OutlinerColumn.wordCount:
          final countA = _countWords(widget.textContents[a.id] ?? '');
          final countB = _countWords(widget.textContents[b.id] ?? '');
          comparison = countA.compareTo(countB);
          break;
        case OutlinerColumn.modified:
          comparison = (metaA?.modifiedAt ?? DateTime(0))
              .compareTo(metaB?.modifiedAt ?? DateTime(0));
          break;
        default:
          comparison = 0;
      }

      return _sortAscending ? comparison : -comparison;
    });

    return items;
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
