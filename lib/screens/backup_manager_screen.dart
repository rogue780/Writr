import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../models/scrivener_project.dart';

/// Screen for managing project backups
class BackupManagerScreen extends StatefulWidget {
  final BackupService backupService;
  final ScrivenerProject? currentProject;
  final Function(ScrivenerProject)? onRestoreProject;

  const BackupManagerScreen({
    super.key,
    required this.backupService,
    this.currentProject,
    this.onRestoreProject,
  });

  @override
  State<BackupManagerScreen> createState() => _BackupManagerScreenState();
}

class _BackupManagerScreenState extends State<BackupManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedProjectFilter;
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Backups', icon: Icon(Icons.backup)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          if (widget.currentProject != null)
            _isCreatingBackup
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _createBackup,
                    tooltip: 'Create Backup Now',
                  ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBackupsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildBackupsTab() {
    final backups = widget.backupService.backups;
    final projectNames = backups.map((b) => b.projectName).toSet().toList()
      ..sort();

    // Filter backups
    final filteredBackups = _selectedProjectFilter == null
        ? backups
        : backups.where((b) => b.projectName == _selectedProjectFilter).toList();

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              const Text('Filter: '),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _selectedProjectFilter,
                hint: const Text('All Projects'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Projects'),
                  ),
                  ...projectNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Text(name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProjectFilter = value;
                  });
                },
              ),
              const Spacer(),
              Text(
                '${filteredBackups.length} backup${filteredBackups.length == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Backups list
        Expanded(
          child: filteredBackups.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.backup, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No backups found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.currentProject != null)
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create First Backup'),
                          onPressed: _createBackup,
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredBackups.length,
                  itemBuilder: (context, index) {
                    final backup = filteredBackups[index];
                    return _BackupListTile(
                      backup: backup,
                      onRestore: () => _restoreBackup(backup),
                      onDelete: () => _deleteBackup(backup),
                      onDownload: () => _downloadBackup(backup),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    final settings = widget.backupService.settings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Auto-backup settings
        _buildSettingsSection(
          'Automatic Backups',
          [
            SwitchListTile(
              title: const Text('Backup on project close'),
              subtitle: const Text('Create a backup when closing a project'),
              value: settings.autoBackupOnClose,
              onChanged: (value) {
                widget.backupService.updateSettings(
                  settings.copyWith(autoBackupOnClose: value),
                );
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Backup on save'),
              subtitle: const Text('Create a backup each time you save'),
              value: settings.autoBackupOnSave,
              onChanged: (value) {
                widget.backupService.updateSettings(
                  settings.copyWith(autoBackupOnSave: value),
                );
                setState(() {});
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Retention settings
        _buildSettingsSection(
          'Retention Policy',
          [
            ListTile(
              title: const Text('Maximum backups per project'),
              subtitle: Text('${settings.maxBackupsPerProject} backups'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: settings.maxBackupsPerProject.toDouble(),
                  min: 5,
                  max: 100,
                  divisions: 19,
                  label: '${settings.maxBackupsPerProject}',
                  onChanged: (value) {
                    widget.backupService.updateSettings(
                      settings.copyWith(maxBackupsPerProject: value.toInt()),
                    );
                    setState(() {});
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Keep backups for'),
              subtitle: Text('${settings.retentionDays} days'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: settings.retentionDays.toDouble(),
                  min: 7,
                  max: 365,
                  divisions: 51,
                  label: '${settings.retentionDays} days',
                  onChanged: (value) {
                    widget.backupService.updateSettings(
                      settings.copyWith(retentionDays: value.toInt()),
                    );
                    setState(() {});
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Storage info
        _buildSettingsSection(
          'Storage',
          [
            ListTile(
              title: const Text('Total backups'),
              subtitle: Text('${widget.backupService.backups.length} backups'),
              trailing: const Icon(Icons.storage),
            ),
            ListTile(
              title: const Text('Total size'),
              subtitle: Text(_calculateTotalSize()),
              trailing: const Icon(Icons.data_usage),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Danger zone
        _buildSettingsSection(
          'Danger Zone',
          [
            ListTile(
              title: const Text('Delete all automatic backups'),
              subtitle: const Text('Keep only manual backups'),
              trailing: TextButton(
                onPressed: _deleteAutoBackups,
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ),
            ListTile(
              title: const Text('Delete all backups'),
              subtitle: const Text('This cannot be undone'),
              trailing: TextButton(
                onPressed: _deleteAllBackups,
                child: const Text('Delete All',
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  String _calculateTotalSize() {
    final totalBytes = widget.backupService.backups
        .fold<int>(0, (sum, backup) => sum + backup.sizeBytes);

    if (totalBytes < 1024) {
      return '$totalBytes B';
    } else if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Future<void> _createBackup() async {
    if (widget.currentProject == null) return;

    // Show description dialog
    final description = await showDialog<String>(
      context: context,
      builder: (context) => _BackupDescriptionDialog(),
    );

    if (!mounted) return;

    setState(() {
      _isCreatingBackup = true;
    });

    try {
      await widget.backupService.createBackup(
        project: widget.currentProject!,
        description: description,
        isAutomatic: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create backup: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });
      }
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to restore this backup?',
            ),
            const SizedBox(height: 16),
            Text('Project: ${backup.projectName}'),
            Text('Created: ${backup.formattedDate}'),
            if (backup.description != null)
              Text('Description: ${backup.description}'),
            const SizedBox(height: 16),
            const Text(
              'Warning: This will replace the current project contents.',
              style: TextStyle(color: Colors.orange),
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

    if (confirm != true) return;

    try {
      final project = await widget.backupService.restoreFromBackup(backup);
      if (project != null && widget.onRestoreProject != null) {
        widget.onRestoreProject!(project);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore backup: $e')),
        );
      }
    }
  }

  void _deleteBackup(BackupInfo backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: Text(
          'Are you sure you want to delete this backup?\n\n'
          '${backup.projectName}\n'
          '${backup.formattedDate}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.backupService.deleteBackup(backup.id);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _downloadBackup(BackupInfo backup) {
    final data = widget.backupService.getBackupData(backup.id);
    if (data != null) {
      // In a real implementation, this would trigger a file download
      // For now, just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading ${backup.fileName}...')),
      );
    }
  }

  void _deleteAutoBackups() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Automatic Backups'),
        content: const Text(
          'This will delete all automatic backups but keep manual backups. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              final autoBackups = widget.backupService.backups
                  .where((b) => b.isAutomatic)
                  .toList();
              for (final backup in autoBackups) {
                widget.backupService.deleteBackup(backup.id);
              }
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted ${autoBackups.length} automatic backups'),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAllBackups() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Backups'),
        content: const Text(
          'This will permanently delete ALL backups. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              final count = widget.backupService.backups.length;
              for (final backup in widget.backupService.backups.toList()) {
                widget.backupService.deleteBackup(backup.id);
              }
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted $count backups')),
              );
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

/// List tile for displaying a backup
class _BackupListTile extends StatelessWidget {
  final BackupInfo backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _BackupListTile({
    required this.backup,
    required this.onRestore,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backup.isAutomatic
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.2),
          child: Icon(
            backup.isAutomatic ? Icons.schedule : Icons.backup,
            color: backup.isAutomatic ? Colors.blue : Colors.green,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                backup.projectName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: backup.isAutomatic
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                backup.isAutomatic ? 'Auto' : 'Manual',
                style: TextStyle(
                  fontSize: 11,
                  color: backup.isAutomatic ? Colors.blue : Colors.green,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  backup.ageDescription,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.storage, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  backup.formattedSize,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (backup.description != null) ...[
              const SizedBox(height: 4),
              Text(
                backup.description!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore, size: 20),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            const PopupMenuDivider(),
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
          onSelected: (value) {
            switch (value) {
              case 'restore':
                onRestore();
                break;
              case 'download':
                onDownload();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
        ),
      ),
    );
  }
}

/// Dialog for entering backup description
class _BackupDescriptionDialog extends StatefulWidget {
  @override
  State<_BackupDescriptionDialog> createState() =>
      _BackupDescriptionDialogState();
}

class _BackupDescriptionDialogState extends State<_BackupDescriptionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add an optional description for this backup:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g., Before major revision',
            ),
            maxLines: 2,
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
            final description =
                _controller.text.trim().isEmpty ? null : _controller.text.trim();
            Navigator.pop(context, description);
          },
          child: const Text('Create Backup'),
        ),
      ],
    );
  }
}
