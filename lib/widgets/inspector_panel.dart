import 'package:flutter/material.dart';
import '../models/scrivener_project.dart';
import '../models/document_metadata.dart';
import '../models/snapshot.dart';
import 'snapshot_viewer.dart';
import 'diff_viewer.dart';

/// Right-side inspector panel for viewing and editing document metadata.
class InspectorPanel extends StatefulWidget {
  final BinderItem? selectedItem;
  final DocumentMetadata? metadata;
  final String? content;
  final List<DocumentSnapshot> snapshots;
  final Function(DocumentMetadata) onMetadataChanged;
  final Function()? onCreateSnapshot;
  final Function(DocumentSnapshot)? onRestoreSnapshot;
  final Function(DocumentSnapshot)? onDeleteSnapshot;
  final bool isPinned;
  final VoidCallback? onTogglePinned;
  final VoidCallback? onClose;

  const InspectorPanel({
    super.key,
    this.selectedItem,
    this.metadata,
    this.content,
    this.snapshots = const [],
    required this.onMetadataChanged,
    this.onCreateSnapshot,
    this.onRestoreSnapshot,
    this.onDeleteSnapshot,
    this.isPinned = false,
    this.onTogglePinned,
    this.onClose,
  });

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _synopsisController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _synopsisController =
        TextEditingController(text: widget.metadata?.synopsis ?? '');
    _notesController =
        TextEditingController(text: widget.metadata?.notes ?? '');
  }

  @override
  void didUpdateWidget(InspectorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItem?.id != widget.selectedItem?.id) {
      _synopsisController.text = widget.metadata?.synopsis ?? '';
      _notesController.text = widget.metadata?.notes ?? '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _synopsisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(icon: Icon(Icons.notes, size: 20), text: 'Synopsis'),
              Tab(icon: Icon(Icons.note_add, size: 20), text: 'Notes'),
              Tab(icon: Icon(Icons.label, size: 20), text: 'Meta'),
              Tab(icon: Icon(Icons.history, size: 20), text: 'Snaps'),
            ],
          ),

          // Tab content
          Expanded(
            child: widget.selectedItem == null
                ? _buildNoSelection(context)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSynopsisTab(context),
                      _buildNotesTab(context),
                      _buildMetadataTab(context),
                      _buildSnapshotsTab(context),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          if (widget.onClose != null) ...[
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: 'Hide Inspector',
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.selectedItem?.title ?? 'Inspector',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.onTogglePinned != null) ...[
            IconButton(
              icon: Icon(
                widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 20,
              ),
              tooltip: widget.isPinned ? 'Unpin' : 'Pin',
              onPressed: widget.onTogglePinned,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildNoSelection(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a document\nto view its details',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsisTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Synopsis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _synopsisController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Write a brief synopsis...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                if (widget.metadata != null) {
                  widget.onMetadataChanged(
                    widget.metadata!.copyWith(
                      synopsis: value,
                      modifiedAt: DateTime.now(),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_synopsisController.text.length} characters',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Notes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Add notes about this document...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (value) {
                if (widget.metadata != null) {
                  widget.onMetadataChanged(
                    widget.metadata!.copyWith(
                      notes: value,
                      modifiedAt: DateTime.now(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataTab(BuildContext context) {
    final metadata = widget.metadata;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label section
          _buildSectionHeader('Label'),
          const SizedBox(height: 8),
          _buildLabelSelector(context),
          const SizedBox(height: 16),

          // Status section
          _buildSectionHeader('Status'),
          const SizedBox(height: 8),
          _buildStatusDropdown(context),
          const SizedBox(height: 16),

          // Word count target
          _buildSectionHeader('Word Count Target'),
          const SizedBox(height: 8),
          _buildWordCountTarget(context),
          const SizedBox(height: 16),

          // Include in compile
          _buildIncludeInCompile(context),
          const SizedBox(height: 16),

          // Timestamps
          _buildSectionHeader('Information'),
          const SizedBox(height: 8),
          if (metadata != null) ...[
            _buildInfoRow('Created', _formatDate(metadata.createdAt)),
            _buildInfoRow('Modified', _formatDate(metadata.modifiedAt)),
            if (widget.content != null)
              _buildInfoRow('Words', '${_countWords(widget.content!)}'),
          ],
        ],
      ),
    );
  }

  Widget _buildSnapshotsTab(BuildContext context) {
    // If no snapshot callbacks are provided, show placeholder
    if (widget.onCreateSnapshot == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Snapshots not available',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return SnapshotViewer(
      snapshots: widget.snapshots,
      currentContent: widget.content,
      onCreateSnapshot: widget.onCreateSnapshot!,
      onRestoreSnapshot: (snapshot) {
        widget.onRestoreSnapshot?.call(snapshot);
      },
      onDeleteSnapshot: (snapshot) {
        widget.onDeleteSnapshot?.call(snapshot);
      },
      onCompareSnapshot: (snapshot) {
        // Show diff viewer dialog
        DiffViewer.show(
          context: context,
          title: 'Compare: ${snapshot.title}',
          oldText: snapshot.content,
          newText: widget.content ?? '',
          oldLabel: 'Snapshot (${snapshot.formattedDate})',
          newLabel: 'Current',
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildLabelSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // No label option
        _buildLabelChip(context, null, 'None'),
        // Predefined labels
        ...DocumentLabel.predefinedLabels.map(
          (label) => _buildLabelChip(context, label, label.name),
        ),
      ],
    );
  }

  Widget _buildLabelChip(
      BuildContext context, DocumentLabel? label, String name) {
    final isSelected = widget.metadata?.label?.name == label?.name;
    final color = label != null ? Color(label.colorValue) : Colors.grey;

    return FilterChip(
      label: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (widget.metadata != null) {
          widget.onMetadataChanged(
            widget.metadata!.copyWith(
              label: selected ? label : null,
              modifiedAt: DateTime.now(),
            ),
          );
        }
      },
      backgroundColor: color.withValues(alpha: 0.2),
      selectedColor: color,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return DropdownButtonFormField<DocumentStatus>(
      initialValue: widget.metadata?.status ?? DocumentStatus.noStatus,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: DocumentStatus.values.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status.displayName),
        );
      }).toList(),
      onChanged: (status) {
        if (widget.metadata != null && status != null) {
          widget.onMetadataChanged(
            widget.metadata!.copyWith(
              status: status,
              modifiedAt: DateTime.now(),
            ),
          );
        }
      },
    );
  }

  Widget _buildWordCountTarget(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Enter target...',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixText: 'words',
      ),
      controller: TextEditingController(
        text: widget.metadata?.wordCountTarget?.toString() ?? '',
      ),
      onChanged: (value) {
        final target = int.tryParse(value);
        if (widget.metadata != null) {
          widget.onMetadataChanged(
            widget.metadata!.copyWith(
              wordCountTarget: target,
              modifiedAt: DateTime.now(),
            ),
          );
        }
      },
    );
  }

  Widget _buildIncludeInCompile(BuildContext context) {
    return CheckboxListTile(
      value: widget.metadata?.includeInCompile ?? true,
      onChanged: (value) {
        if (widget.metadata != null) {
          widget.onMetadataChanged(
            widget.metadata!.copyWith(
              includeInCompile: value ?? true,
              modifiedAt: DateTime.now(),
            ),
          );
        }
      },
      title: const Text('Include in Compile'),
      subtitle: const Text('Include this document when compiling'),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }
}
