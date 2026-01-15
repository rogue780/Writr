import 'package:flutter/material.dart';
import '../models/target.dart';
import '../models/scrivener_project.dart';
import '../services/target_service.dart';

/// Compact progress indicator for toolbar
class TargetProgressIndicator extends StatelessWidget {
  final TargetProgress progress;
  final bool showLabel;
  final double height;

  const TargetProgressIndicator({
    super.key,
    required this.progress,
    this.showLabel = true,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${progress.target.name}: ${(progress.progress * 100).toInt()}% '
          '(${progress.currentCount}/${progress.target.targetCount} '
          '${progress.target.unit.displayName.toLowerCase()})',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                progress.target.name,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Container(
            width: 100,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progress.statusColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed progress card for targets panel
class TargetProgressCard extends StatelessWidget {
  final TargetProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TargetProgressCard({
    super.key,
    required this.progress,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final target = progress.target;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(
                    target.type.icon,
                    size: 20,
                    color: progress.statusColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      target.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (progress.isComplete)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(progress.statusColor),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 8),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.currentCount} / ${target.targetCount} ${target.unit.abbreviation}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${(progress.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: progress.statusColor,
                    ),
                  ),
                ],
              ),

              // Deadline info
              if (target.deadline != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      target.isOverdue ? Icons.warning : Icons.schedule,
                      size: 14,
                      color: target.isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      target.isOverdue
                          ? 'Overdue'
                          : '${target.daysUntilDeadline} days left',
                      style: TextStyle(
                        fontSize: 11,
                        color: target.isOverdue ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],

              // Remaining
              if (!progress.isComplete) ...[
                const SizedBox(height: 4),
                Text(
                  '${progress.remaining} ${target.unit.displayName.toLowerCase()} to go',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Session target widget with real-time updates
class SessionTargetWidget extends StatelessWidget {
  final SessionTarget session;
  final VoidCallback? onEnd;

  const SessionTargetWidget({
    super.key,
    required this.session,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Session Target',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (session.isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Complete!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (onEnd != null)
                  IconButton(
                    icon: const Icon(Icons.stop, size: 20),
                    onPressed: onEnd,
                    tooltip: 'End Session',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: session.progress,
                backgroundColor: colorScheme.surface,
                valueColor: AlwaysStoppedAnimation(
                  session.isComplete ? Colors.green : colorScheme.primary,
                ),
                minHeight: 10,
              ),
            ),

            const SizedBox(height: 8),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('Written', '${session.wordsWritten}'),
                _buildStat('Target', '${session.targetWords}'),
                _buildStat('Remaining', '${session.wordsRemaining}'),
              ],
            ),

            const SizedBox(height: 8),

            // Time stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('Time', _formatDuration(session.elapsed)),
                _buildStat('WPM', session.wordsPerMinute.toStringAsFixed(1)),
                if (session.estimatedTimeRemaining != null)
                  _buildStat('ETA', _formatDuration(session.estimatedTimeRemaining!)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Circular progress indicator for binder items
class DocumentTargetIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;

  const DocumentTargetIndicator({
    super.key,
    required this.progress,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _getColorForProgress(progress);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(effectiveColor),
          ),
          if (progress >= 1.0)
            Center(
              child: Icon(
                Icons.check,
                size: size * 0.6,
                color: effectiveColor,
              ),
            ),
        ],
      ),
    );
  }

  Color _getColorForProgress(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.75) return Colors.lightGreen;
    if (progress >= 0.5) return Colors.orange;
    if (progress >= 0.25) return Colors.deepOrange;
    return Colors.grey;
  }
}

/// Targets panel for inspector
class TargetsPanel extends StatelessWidget {
  final TargetService targetService;
  final ScrivenerProject project;
  final VoidCallback? onAddTarget;
  final Function(WritingTarget)? onEditTarget;
  final Function(String)? onDeleteTarget;

  const TargetsPanel({
    super.key,
    required this.targetService,
    required this.project,
    this.onAddTarget,
    this.onEditTarget,
    this.onDeleteTarget,
  });

  @override
  Widget build(BuildContext context) {
    final targets = targetService.activeTargets;
    final progressList = targetService.getAllTargetProgress(project);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.track_changes, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Targets',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (onAddTarget != null)
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onAddTarget,
                  tooltip: 'Add Target',
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Session target
        if (targetService.sessionTarget != null)
          SessionTargetWidget(
            session: targetService.sessionTarget!,
            onEnd: () => targetService.endSessionTarget(),
          ),

        // Targets list
        if (targets.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No targets set.\nAdd a target to track your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: progressList.length,
              itemBuilder: (context, index) {
                final progress = progressList[index];
                return TargetProgressCard(
                  progress: progress,
                  onEdit: onEditTarget != null
                      ? () => onEditTarget!(progress.target)
                      : null,
                  onDelete: onDeleteTarget != null
                      ? () => onDeleteTarget!(progress.target.id)
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Dialog for creating/editing targets
class TargetEditDialog extends StatefulWidget {
  final WritingTarget? target;
  final List<BinderItem>? documents;

  const TargetEditDialog({
    super.key,
    this.target,
    this.documents,
  });

  @override
  State<TargetEditDialog> createState() => _TargetEditDialogState();
}

class _TargetEditDialogState extends State<TargetEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _countController;
  late TargetType _type;
  late TargetUnit _unit;
  DateTime? _deadline;
  String? _selectedDocumentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.target?.name ?? '');
    _countController = TextEditingController(
      text: widget.target?.targetCount.toString() ?? '1000',
    );
    _type = widget.target?.type ?? TargetType.project;
    _unit = widget.target?.unit ?? TargetUnit.words;
    _deadline = widget.target?.deadline;
    _selectedDocumentId = widget.target?.documentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.target == null ? 'Create Target' : 'Edit Target'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Target Name',
                  hintText: 'e.g., Novel Draft',
                ),
              ),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<TargetType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Target Type',
                ),
                items: TargetType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Document selector (for document targets)
              if (_type == TargetType.document && widget.documents != null)
                DropdownButtonFormField<String>(
                  initialValue: _selectedDocumentId,
                  decoration: const InputDecoration(
                    labelText: 'Document',
                  ),
                  items: widget.documents!
                      .where((d) => !d.isFolder)
                      .map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc.title),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedDocumentId = value);
                  },
                ),

              if (_type == TargetType.document)
                const SizedBox(height: 16),

              // Count and unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Count',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<TargetUnit>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                      items: TargetUnit.values.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _unit = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deadline
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'No deadline'
                          : 'Deadline: ${_formatDate(_deadline!)}',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_deadline == null ? 'Set' : 'Change'),
                    onPressed: _selectDeadline,
                  ),
                  if (_deadline != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _deadline = null),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.target == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _deadline = date);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final count = int.tryParse(_countController.text) ?? 1000;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target name')),
      );
      return;
    }

    if (_type == TargetType.document && _selectedDocumentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document')),
      );
      return;
    }

    final target = WritingTarget(
      id: widget.target?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: _type,
      targetCount: count,
      unit: _unit,
      deadline: _deadline,
      createdAt: widget.target?.createdAt ?? DateTime.now(),
      documentId: _type == TargetType.document ? _selectedDocumentId : null,
    );

    Navigator.pop(context, target);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Quick session target dialog
class SessionTargetDialog extends StatefulWidget {
  const SessionTargetDialog({super.key});

  @override
  State<SessionTargetDialog> createState() => _SessionTargetDialogState();
}

class _SessionTargetDialogState extends State<SessionTargetDialog> {
  final _controller = TextEditingController(text: '500');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many words do you want to write this session?'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Word Target',
              suffixText: 'words',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [250, 500, 1000, 2000].map((count) {
              return ActionChip(
                label: Text('$count'),
                onPressed: () => _controller.text = count.toString(),
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
        FilledButton(
          onPressed: () {
            final count = int.tryParse(_controller.text) ?? 500;
            Navigator.pop(context, count);
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}
