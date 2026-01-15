import 'package:flutter/material.dart';
import '../models/snapshot.dart';

/// Widget for viewing and managing document snapshots.
class SnapshotViewer extends StatefulWidget {
  final List<DocumentSnapshot> snapshots;
  final String? currentContent;
  final Function() onCreateSnapshot;
  final Function(DocumentSnapshot) onRestoreSnapshot;
  final Function(DocumentSnapshot) onDeleteSnapshot;
  final Function(DocumentSnapshot)? onCompareSnapshot;

  const SnapshotViewer({
    super.key,
    required this.snapshots,
    this.currentContent,
    required this.onCreateSnapshot,
    required this.onRestoreSnapshot,
    required this.onDeleteSnapshot,
    this.onCompareSnapshot,
  });

  @override
  State<SnapshotViewer> createState() => _SnapshotViewerState();
}

class _SnapshotViewerState extends State<SnapshotViewer> {
  DocumentSnapshot? _selectedSnapshot;
  bool _showPreview = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Create snapshot button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: widget.onCreateSnapshot,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Take Snapshot'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const Divider(height: 1),
        // Snapshots list
        Expanded(
          child: widget.snapshots.isEmpty
              ? _buildEmptyState()
              : _buildSnapshotsList(),
        ),
        // Preview panel
        if (_showPreview && _selectedSnapshot != null)
          _buildPreviewPanel(_selectedSnapshot!),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No snapshots yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a snapshot to save the current\nversion of your document',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotsList() {
    return ListView.builder(
      itemCount: widget.snapshots.length,
      itemBuilder: (context, index) {
        final snapshot = widget.snapshots[index];
        final isSelected = _selectedSnapshot?.id == snapshot.id;

        return _buildSnapshotTile(snapshot, isSelected);
      },
    );
  }

  Widget _buildSnapshotTile(DocumentSnapshot snapshot, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (_selectedSnapshot?.id == snapshot.id) {
              _selectedSnapshot = null;
              _showPreview = false;
            } else {
              _selectedSnapshot = snapshot;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with actions
              Row(
                children: [
                  Icon(
                    Icons.camera,
                    size: 16,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      snapshot.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Action buttons
                  if (isSelected) ...[
                    _buildActionButton(
                      icon: Icons.visibility,
                      tooltip: 'Preview',
                      onPressed: () {
                        setState(() {
                          _showPreview = !_showPreview;
                        });
                      },
                      isActive: _showPreview,
                    ),
                    _buildActionButton(
                      icon: Icons.compare_arrows,
                      tooltip: 'Compare',
                      onPressed: () {
                        if (widget.onCompareSnapshot != null) {
                          widget.onCompareSnapshot!(snapshot);
                        }
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.restore,
                      tooltip: 'Restore',
                      onPressed: () => _confirmRestore(snapshot),
                    ),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(snapshot),
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Date and info row
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    snapshot.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.text_snippet,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${snapshot.wordCount} words',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Note if present
              if (snapshot.note != null && snapshot.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  snapshot.note!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            icon,
            size: 18,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : color ?? Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(DocumentSnapshot snapshot) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.preview, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Preview',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _showPreview = false;
                    });
                  },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(
                snapshot.content.isEmpty
                    ? '(Empty document)'
                    : snapshot.content,
                style: TextStyle(
                  fontSize: 13,
                  color: snapshot.content.isEmpty ? Colors.grey : null,
                  fontStyle:
                      snapshot.content.isEmpty ? FontStyle.italic : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(DocumentSnapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Snapshot?'),
        content: Text(
          'This will replace the current document content with the snapshot from ${snapshot.formattedDate}.\n\n'
          'A snapshot of the current content will be created automatically before restoring.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRestoreSnapshot(snapshot);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(DocumentSnapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snapshot?'),
        content: Text(
          'Are you sure you want to delete the snapshot from ${snapshot.formattedDate}?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteSnapshot(snapshot);
              if (_selectedSnapshot?.id == snapshot.id) {
                setState(() {
                  _selectedSnapshot = null;
                  _showPreview = false;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
