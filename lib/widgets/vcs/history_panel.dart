import 'package:flutter/material.dart';
import '../../models/vcs/commit.dart';
import '../../services/vcs_service.dart';

/// Panel showing version control history (commits, branches).
class VcsHistoryPanel extends StatefulWidget {
  final VcsService vcsService;
  final VoidCallback? onClose;
  final Function(VcsCommit commit)? onViewCommit;
  final Function(VcsCommit commit)? onRestoreCommit;

  const VcsHistoryPanel({
    super.key,
    required this.vcsService,
    this.onClose,
    this.onViewCommit,
    this.onRestoreCommit,
  });

  @override
  State<VcsHistoryPanel> createState() => _VcsHistoryPanelState();
}

class _VcsHistoryPanelState extends State<VcsHistoryPanel> {
  List<VcsHistoryEntry> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    widget.vcsService.addListener(_onVcsChanged);
  }

  @override
  void dispose() {
    widget.vcsService.removeListener(_onVcsChanged);
    super.dispose();
  }

  void _onVcsChanged() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await widget.vcsService.getHistory(limit: 100);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          _buildBranchSelector(context),
          const Divider(height: 1),
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Version History',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: _loadHistory,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (widget.onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Close',
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBranchSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentBranch = widget.vcsService.currentBranch;
    final branches = widget.vcsService.branches;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Icon(Icons.account_tree, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currentBranch?.name,
                isDense: true,
                isExpanded: true,
                hint: const Text('No branch'),
                items: branches.map((branch) {
                  return DropdownMenuItem(
                    value: branch.name,
                    child: Row(
                      children: [
                        if (branch.name == currentBranch?.name)
                          Icon(Icons.check, size: 16, color: colorScheme.primary),
                        if (branch.name == currentBranch?.name)
                          const SizedBox(width: 4),
                        Expanded(child: Text(branch.name)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (branchName) async {
                  if (branchName != null && branchName != currentBranch?.name) {
                    try {
                      await widget.vcsService.checkoutBranch(branchName);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error switching branch: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'New Branch',
            onPressed: () => _showCreateBranchDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading history',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No history yet',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Save your project to create the first version',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final entry = _history[index];
        return _buildCommitTile(context, entry, index);
      },
    );
  }

  Widget _buildCommitTile(BuildContext context, VcsHistoryEntry entry, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final commit = entry.commit;
    final isHead = entry.isHead;

    return InkWell(
      onTap: widget.onViewCommit != null ? () => widget.onViewCommit!(commit) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHead ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Graph line and dot
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  if (index > 0)
                    Container(
                      width: 2,
                      height: 8,
                      color: colorScheme.outline,
                    ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHead ? colorScheme.primary : colorScheme.outline,
                      border: commit.isMergeCommit
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                  ),
                  if (index < _history.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: colorScheme.outline,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Commit info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message
                  Text(
                    commit.message,
                    style: TextStyle(
                      fontWeight: isHead ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Timestamp and hash
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(commit.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        commit.hash.substring(0, 7),
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Branch badges
                  if (entry.branchNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: entry.branchNames.map((name) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurfaceVariant),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('View Changes'),
                    ],
                  ),
                ),
                if (!isHead)
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore, size: 18),
                        SizedBox(width: 8),
                        Text('Restore'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'branch',
                  child: Row(
                    children: [
                      Icon(Icons.account_tree, size: 18),
                      SizedBox(width: 8),
                      Text('Create Branch Here'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    widget.onViewCommit?.call(commit);
                    break;
                  case 'restore':
                    _confirmRestore(context, commit);
                    break;
                  case 'branch':
                    _showCreateBranchDialog(context, fromCommit: commit);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  Future<void> _showCreateBranchDialog(BuildContext context, {VcsCommit? fromCommit}) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Branch Name',
                hintText: 'e.g., alternate-ending',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this branch for?',
              ),
              maxLines: 2,
            ),
            if (fromCommit != null) ...[
              const SizedBox(height: 16),
              Text(
                'From: ${fromCommit.message}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty && mounted) {
      try {
        await widget.vcsService.createBranch(
          nameController.text.trim().replaceAll(' ', '-'),
          description: descController.text.isNotEmpty ? descController.text : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Branch "${nameController.text}" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating branch: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmRestore(BuildContext context, VcsCommit commit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Version'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to restore to this version?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commit.message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(commit.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your current changes will be saved as a new version before restoring.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      widget.onRestoreCommit?.call(commit);
    }
  }
}

/// Shows the VCS history panel as a dialog.
class VcsHistoryDialog extends StatelessWidget {
  final VcsService vcsService;

  const VcsHistoryDialog({super.key, required this.vcsService});

  static Future<void> show(BuildContext context, VcsService vcsService) {
    return showDialog(
      context: context,
      builder: (context) => VcsHistoryDialog(vcsService: vcsService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 400,
          height: 600,
          child: VcsHistoryPanel(
            vcsService: vcsService,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}
