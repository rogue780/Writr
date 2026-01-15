import 'package:flutter/material.dart';
import '../models/comment.dart';

/// Widget for displaying a comment bubble in the margin
class CommentBubble extends StatelessWidget {
  final DocumentComment comment;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onResolve;
  final VoidCallback? onDelete;
  final Function(String)? onReply;
  final Function(String)? onEdit;

  const CommentBubble({
    super.key,
    required this.comment,
    this.isSelected = false,
    this.onTap,
    this.onResolve,
    this.onDelete,
    this.onReply,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightColor = Color(comment.colorValue);

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : highlightColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with author and actions
            _buildHeader(context, highlightColor),

            // Comment text
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                comment.commentText,
                style: TextStyle(
                  fontSize: 13,
                  decoration:
                      comment.isResolved ? TextDecoration.lineThrough : null,
                  color: comment.isResolved ? Colors.grey : null,
                ),
              ),
            ),

            // Replies
            if (comment.replies.isNotEmpty) _buildReplies(context),

            // Reply input (when selected)
            if (isSelected && onReply != null) _buildReplyInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color highlightColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      decoration: BoxDecoration(
        color: highlightColor.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
      ),
      child: Row(
        children: [
          if (comment.author != null) ...[
            Icon(Icons.person, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              comment.author!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _formatDate(comment.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const Spacer(),
          if (comment.isResolved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Resolved',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          _buildPopupMenu(context),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
        if (onResolve != null)
          PopupMenuItem(
            value: 'resolve',
            child: Text(comment.isResolved ? 'Unresolve' : 'Resolve'),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditDialog(context);
            break;
          case 'resolve':
            onResolve?.call();
            break;
          case 'delete':
            _confirmDelete(context);
            break;
        }
      },
    );
  }

  Widget _buildReplies(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: comment.replies.map((reply) => _buildReply(reply)).toList(),
      ),
    );
  }

  Widget _buildReply(CommentReply reply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (reply.author != null)
                Text(
                  reply.author!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                _formatDate(reply.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(reply.text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildReplyInput(BuildContext context) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Reply...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              style: const TextStyle(fontSize: 12),
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  onReply?.call(text);
                  controller.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.send, size: 18),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onReply?.call(controller.text);
                controller.clear();
              }
            },
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: comment.commentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onEdit?.call(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete?.call();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Widget for displaying a list of comments in a panel
class CommentListPanel extends StatelessWidget {
  final List<DocumentComment> comments;
  final String? selectedCommentId;
  final Function(DocumentComment)? onCommentSelected;
  final Function(String commentId)? onResolve;
  final Function(String commentId)? onDelete;
  final Function(String commentId, String replyText)? onReply;
  final Function(String commentId, String newText)? onEdit;
  final bool showResolved;
  final VoidCallback? onToggleShowResolved;

  const CommentListPanel({
    super.key,
    required this.comments,
    this.selectedCommentId,
    this.onCommentSelected,
    this.onResolve,
    this.onDelete,
    this.onReply,
    this.onEdit,
    this.showResolved = true,
    this.onToggleShowResolved,
  });

  @override
  Widget build(BuildContext context) {
    final filteredComments = showResolved
        ? comments
        : comments.where((c) => !c.isResolved).toList();

    return Column(
      children: [
        // Header
        _buildHeader(context),

        // Comment list
        Expanded(
          child: filteredComments.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredComments.length,
                  itemBuilder: (context, index) {
                    final comment = filteredComments[index];
                    return CommentBubble(
                      comment: comment,
                      isSelected: comment.id == selectedCommentId,
                      onTap: () => onCommentSelected?.call(comment),
                      onResolve: onResolve != null
                          ? () => onResolve!(comment.id)
                          : null,
                      onDelete: onDelete != null
                          ? () => onDelete!(comment.id)
                          : null,
                      onReply: onReply != null
                          ? (text) => onReply!(comment.id, text)
                          : null,
                      onEdit: onEdit != null
                          ? (text) => onEdit!(comment.id, text)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final unresolvedCount = comments.where((c) => !c.isResolved).length;
    final resolvedCount = comments.where((c) => c.isResolved).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.comment, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Comments',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$unresolvedCount',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (resolvedCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$resolvedCount resolved',
                style: const TextStyle(fontSize: 11, color: Colors.green),
              ),
            ),
          ],
          const Spacer(),
          if (onToggleShowResolved != null && resolvedCount > 0)
            TextButton.icon(
              onPressed: onToggleShowResolved,
              icon: Icon(
                showResolved ? Icons.visibility_off : Icons.visibility,
                size: 16,
              ),
              label: Text(
                showResolved ? 'Hide resolved' : 'Show resolved',
                style: const TextStyle(fontSize: 12),
              ),
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
          Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            showResolved ? 'No comments yet' : 'No unresolved comments',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Select text and add a comment',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

/// Color picker for comment highlight colors
class CommentColorPicker extends StatelessWidget {
  final int selectedColor;
  final Function(int) onColorSelected;

  const CommentColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CommentColors.all.map((color) {
        final isSelected = color == selectedColor;
        return InkWell(
          onTap: () => onColorSelected(color),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.black54)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Dialog for creating a new comment
class NewCommentDialog extends StatefulWidget {
  final String? initialText;
  final String? author;
  final Function(String commentText, int colorValue) onCreate;

  const NewCommentDialog({
    super.key,
    this.initialText,
    this.author,
    required this.onCreate,
  });

  @override
  State<NewCommentDialog> createState() => _NewCommentDialogState();
}

class _NewCommentDialogState extends State<NewCommentDialog> {
  late final TextEditingController _controller;
  int _selectedColor = CommentColors.yellow;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Comment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter your comment...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Highlight Color',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          CommentColorPicker(
            selectedColor: _selectedColor,
            onColorSelected: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onCreate(_controller.text, _selectedColor);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add Comment'),
        ),
      ],
    );
  }
}
