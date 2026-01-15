import 'package:flutter/material.dart';
import '../models/snapshot.dart';

/// A dialog/widget for viewing differences between two text versions.
class DiffViewer extends StatelessWidget {
  final String title;
  final String oldText;
  final String newText;
  final String oldLabel;
  final String newLabel;

  const DiffViewer({
    super.key,
    required this.title,
    required this.oldText,
    required this.newText,
    this.oldLabel = 'Snapshot',
    this.newLabel = 'Current',
  });

  /// Shows the diff viewer as a dialog.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String oldText,
    required String newText,
    String oldLabel = 'Snapshot',
    String newLabel = 'Current',
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 700),
          child: DiffViewer(
            title: title,
            oldText: oldText,
            newText: newText,
            oldLabel: oldLabel,
            newLabel: newLabel,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diff = TextDiff.compute(oldText, newText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        _buildHeader(context, diff),
        const Divider(height: 1),
        // Diff content
        Expanded(
          child: diff.hasChanges
              ? _buildDiffContent(context, diff)
              : _buildNoChanges(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, TextDiff diff) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.compare_arrows),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip(
                      context,
                      '+${diff.addedCount}',
                      Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      context,
                      '-${diff.removedCount}',
                      Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${diff.unchangedCount} unchanged',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNoChanges(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No differences found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The snapshot and current content are identical',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffContent(BuildContext context, TextDiff diff) {
    return Row(
      children: [
        // Side-by-side view headers
        Expanded(
          child: Column(
            children: [
              _buildColumnHeader(context, oldLabel, Icons.history),
              Expanded(
                child: _buildTextColumn(
                  context,
                  diff,
                  showOld: true,
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        Expanded(
          child: Column(
            children: [
              _buildColumnHeader(context, newLabel, Icons.article),
              Expanded(
                child: _buildTextColumn(
                  context,
                  diff,
                  showOld: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumnHeader(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTextColumn(
    BuildContext context,
    TextDiff diff, {
    required bool showOld,
  }) {
    return Container(
      color: Colors.grey[50],
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: diff.segments.length,
        itemBuilder: (context, index) {
          final segment = diff.segments[index];
          return _buildDiffLine(context, segment, showOld);
        },
      ),
    );
  }

  Widget _buildDiffLine(
    BuildContext context,
    DiffSegment segment,
    bool showOld,
  ) {
    // Determine visibility and styling based on diff type and column
    Color? backgroundColor;
    Color? textColor;
    bool show = true;

    switch (segment.type) {
      case DiffType.unchanged:
        // Show in both columns
        backgroundColor = null;
        textColor = null;
        break;
      case DiffType.added:
        // Only show in new (right) column
        if (showOld) {
          show = false;
        } else {
          backgroundColor = Colors.green.withValues(alpha: 0.1);
          textColor = Colors.green[800];
        }
        break;
      case DiffType.removed:
        // Only show in old (left) column
        if (!showOld) {
          show = false;
        } else {
          backgroundColor = Colors.red.withValues(alpha: 0.1);
          textColor = Colors.red[800];
        }
        break;
    }

    if (!show) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diff indicator
          if (segment.type != DiffType.unchanged)
            Container(
              width: 16,
              margin: const EdgeInsets.only(right: 8),
              child: Text(
                segment.type == DiffType.added ? '+' : '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          // Text content
          Expanded(
            child: Text(
              segment.text.isEmpty ? ' ' : segment.text,
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified diff view showing all changes inline.
class UnifiedDiffViewer extends StatelessWidget {
  final String title;
  final TextDiff diff;

  const UnifiedDiffViewer({
    super.key,
    required this.title,
    required this.diff,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diff.segments.length,
      itemBuilder: (context, index) {
        final segment = diff.segments[index];
        return _buildUnifiedLine(context, segment, index);
      },
    );
  }

  Widget _buildUnifiedLine(
    BuildContext context,
    DiffSegment segment,
    int lineNumber,
  ) {
    Color? backgroundColor;
    Color? textColor;
    String prefix = ' ';

    switch (segment.type) {
      case DiffType.unchanged:
        backgroundColor = null;
        textColor = null;
        prefix = ' ';
        break;
      case DiffType.added:
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green[800];
        prefix = '+';
        break;
      case DiffType.removed:
        backgroundColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.red[800];
        prefix = '-';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number
          SizedBox(
            width: 40,
            child: Text(
              '${lineNumber + 1}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Diff prefix
          SizedBox(
            width: 20,
            child: Text(
              prefix,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Content
          Expanded(
            child: Text(
              segment.text.isEmpty ? ' ' : segment.text,
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
