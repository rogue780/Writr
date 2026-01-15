import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/scrivener_project.dart';
import '../models/comment.dart';
import 'comment_bubble.dart';

/// Rich text editor widget using flutter_quill for formatting support.
class RichTextEditor extends StatefulWidget {
  final BinderItem item;
  final String content;
  final Function(String) onContentChanged;
  final Function(Document)? onDocumentChanged;
  final List<DocumentComment> comments;
  final Function(int startOffset, int endOffset, String text, int color)? onAddComment;
  final Function(String commentId)? onDeleteComment;
  final Function(String commentId, bool resolved)? onResolveComment;
  final Function(String commentId, String text)? onEditComment;
  final Function(String commentId, String replyText)? onReplyToComment;
  final bool showCommentMargin;
  final bool pageViewMode;
  final Function(bool)? onPageViewModeChanged;

  const RichTextEditor({
    super.key,
    required this.item,
    required this.content,
    required this.onContentChanged,
    this.onDocumentChanged,
    this.comments = const [],
    this.onAddComment,
    this.onDeleteComment,
    this.onResolveComment,
    this.onEditComment,
    this.onReplyToComment,
    this.showCommentMargin = true,
    this.pageViewMode = false,
    this.onPageViewModeChanged,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  late QuillController _controller;
  late FocusNode _focusNode;
  bool _hasUnsavedChanges = false;
  bool _isInitializing = true;
  String? _selectedCommentId;

  // Page view settings
  static const double _pageMaxWidth = 800.0;
  static const double _pageMinMargin = 40.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initializeController();
  }

  void _initializeController() {
    _isInitializing = true;
    final document = _createDocumentFromContent(widget.content);
    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // Clear the undo/redo history after initialization
    // This prevents "undo" from erasing the loaded content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.document.history.clear();
      _isInitializing = false;
    });

    _controller.addListener(_onDocumentChanged);
  }

  /// Creates a Document from plain text content.
  /// Uses Delta operations to avoid creating undo history during load.
  Document _createDocumentFromContent(String content) {
    if (content.isEmpty) {
      return Document();
    }

    // Create document with content but clear history afterward
    // to prevent "undo" from removing the initial content
    try {
      final doc = Document();
      doc.insert(0, content);
      return doc;
    } catch (e) {
      return Document();
    }
  }

  @override
  void didUpdateWidget(RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _controller.removeListener(_onDocumentChanged);
      _controller.dispose();
      _initializeController();
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onDocumentChanged() {
    // Don't mark as changed during initialization
    if (_isInitializing) return;

    setState(() {
      _hasUnsavedChanges = true;
    });

    // Convert document to plain text for storage
    final plainText = _controller.document.toPlainText();
    widget.onContentChanged(plainText);

    // Also notify with full document if callback provided
    widget.onDocumentChanged?.call(_controller.document);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Document header
          _buildHeader(context),

          // Formatting toolbar
          if (widget.item.type == BinderItemType.text) _buildToolbar(context),

          // Editor area with optional comment margin
          Expanded(
            child: widget.item.type == BinderItemType.text
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main editor
                      Expanded(child: _buildEditor(context)),
                      // Comment margin
                      if (widget.showCommentMargin && widget.comments.isNotEmpty)
                        _buildCommentMargin(context),
                    ],
                  )
                : _buildNonEditableView(context),
          ),

          // Status bar
          if (widget.item.type == BinderItemType.text) _buildStatusBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIconForType(widget.item.type),
            size: 20,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Unsaved',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: QuillSimpleToolbar(
              controller: _controller,
              config: const QuillSimpleToolbarConfig(
                showAlignmentButtons: true,
                showBackgroundColorButton: true,
                showBoldButton: true,
                showCenterAlignment: true,
                showClearFormat: true,
                showCodeBlock: false,
                showColorButton: true,
                showDirection: false,
                showDividers: true,
                showFontFamily: true,
                showFontSize: true,
                showHeaderStyle: true,
                showIndent: true,
                showInlineCode: false,
                showItalicButton: true,
                showJustifyAlignment: true,
                showLeftAlignment: true,
                showLink: true,
                showListBullets: true,
                showListCheck: false,
                showListNumbers: true,
                showQuote: true,
                showRedo: true,
                showRightAlignment: true,
                showSearchButton: false,
                showSmallButton: false,
                showStrikeThrough: true,
                showSubscript: false,
                showSuperscript: false,
                showUnderLineButton: true,
                showUndo: true,
                multiRowsDisplay: false,
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 24,
            color: Theme.of(context).dividerColor,
          ),
          // Page view toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton(
              icon: Icon(
                widget.pageViewMode ? Icons.article : Icons.article_outlined,
                size: 20,
              ),
              onPressed: () {
                widget.onPageViewModeChanged?.call(!widget.pageViewMode);
              },
              tooltip: widget.pageViewMode ? 'Switch to Standard View' : 'Switch to Page View',
              color: widget.pageViewMode
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          // Add comment button
          if (widget.onAddComment != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: IconButton(
                icon: const Icon(Icons.add_comment, size: 20),
                onPressed: _showAddCommentDialog,
                tooltip: 'Add Comment',
              ),
            ),
        ],
      ),
    );
  }

  void _showAddCommentDialog() {
    final selection = _controller.selection;
    if (selection.baseOffset == selection.extentOffset) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select text to add a comment')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => NewCommentDialog(
        onCreate: (commentText, colorValue) {
          widget.onAddComment?.call(
            selection.baseOffset,
            selection.extentOffset,
            commentText,
            colorValue,
          );
        },
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final editor = QuillEditor.basic(
      controller: _controller,
      config: const QuillEditorConfig(
        placeholder: 'Start writing...',
        padding: EdgeInsets.zero,
        autoFocus: true,
        expands: true,
        scrollable: true,
      ),
    );

    // Page view mode - centered paper-like container
    if (widget.pageViewMode) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
            margin: const EdgeInsets.symmetric(
              horizontal: _pageMinMargin,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 48,
                vertical: 32,
              ),
              child: editor,
            ),
          ),
        ),
      );
    }

    // Standard edge-to-edge mode
    return Padding(
      padding: const EdgeInsets.all(16),
      child: editor,
    );
  }

  Widget _buildNonEditableView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForType(widget.item.type),
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'This item type is not editable',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    final plainText = _controller.document.toPlainText();
    final wordCount = _countWords(plainText);
    final charCount = plainText.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Words: $wordCount',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Text(
            'Characters: $charCount',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
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

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  Widget _buildCommentMargin(BuildContext context) {
    // Sort comments by their start offset
    final sortedComments = [...widget.comments]
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.comment, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Comments (${widget.comments.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Comment list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sortedComments.length,
              itemBuilder: (context, index) {
                final comment = sortedComments[index];
                return CommentBubble(
                  comment: comment,
                  isSelected: comment.id == _selectedCommentId,
                  onTap: () {
                    setState(() {
                      _selectedCommentId = comment.id;
                    });
                    // Navigate to comment position in editor
                    _navigateToComment(comment);
                  },
                  onResolve: widget.onResolveComment != null
                      ? () => widget.onResolveComment!(
                            comment.id,
                            !comment.isResolved,
                          )
                      : null,
                  onDelete: widget.onDeleteComment != null
                      ? () => widget.onDeleteComment!(comment.id)
                      : null,
                  onReply: widget.onReplyToComment != null
                      ? (text) => widget.onReplyToComment!(comment.id, text)
                      : null,
                  onEdit: widget.onEditComment != null
                      ? (text) => widget.onEditComment!(comment.id, text)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToComment(DocumentComment comment) {
    // Move cursor to the start of the commented text
    _controller.updateSelection(
      TextSelection(
        baseOffset: comment.startOffset,
        extentOffset: comment.endOffset,
      ),
      ChangeSource.local,
    );
    _focusNode.requestFocus();
  }
}
