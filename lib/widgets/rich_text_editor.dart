import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import '../models/comment.dart';
import '../models/scrivener_project.dart';
import 'comment_bubble.dart';
import 'super_editor_style_phases.dart';

/// Rich text editor widget using SuperEditor for formatting support.
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
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  final _documentLayoutKey = GlobalKey();
  late final List<SingleColumnLayoutStylePhase> _customStylePhases;

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
    _scrollController = ScrollController();
    _customStylePhases = [ClampInvalidTextSelectionStylePhase()];
    _initializeEditor();
  }

  void _initializeEditor() {
    _isInitializing = true;
    _document = _createDocumentFromContent(widget.content);
    _composer = MutableDocumentComposer();
    _editor = createDefaultDocumentEditor(
      document: _document,
      composer: _composer,
    );

    _document.addListener(_onDocumentChangeLog);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    });
  }

  MutableDocument _createDocumentFromContent(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    var lines = normalized.split('\n');

    // SuperEditor serializes each TextNode with a trailing '\n'. If the input
    // already ends with '\n', avoid creating an extra empty paragraph node.
    if (normalized.endsWith('\n') && lines.isNotEmpty && lines.last.isEmpty) {
      lines = lines.sublist(0, lines.length - 1);
    }

    if (lines.isEmpty) {
      return MutableDocument.empty();
    }

    return MutableDocument(
      nodes: [
        for (final line in lines)
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText(line),
          ),
      ],
    );
  }

  @override
  void didUpdateWidget(RichTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _document.removeListener(_onDocumentChangeLog);
      _document.dispose();
      _composer.dispose();

      _initializeEditor();

      setState(() {
        _hasUnsavedChanges = false;
      });
    }
  }

  @override
  void dispose() {
    _document.removeListener(_onDocumentChangeLog);
    _document.dispose();
    _composer.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDocumentChangeLog(DocumentChangeLog changeLog) {
    if (_isInitializing) return;

    setState(() {
      _hasUnsavedChanges = true;
    });

    final plainText = _document.toPlainText();
    widget.onContentChanged(plainText);
    widget.onDocumentChanged?.call(_document);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          if (widget.item.type == BinderItemType.text) _buildToolbar(context),
          Expanded(
            child: widget.item.type == BinderItemType.text
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildEditor(context)),
                      if (widget.showCommentMargin && widget.comments.isNotEmpty)
                        _buildCommentMargin(context),
                    ],
                  )
                : _buildNonEditableView(context),
          ),
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
          IconButton(
            icon: const Icon(Icons.format_bold, size: 20),
            tooltip: 'Bold',
            onPressed: () => _toggleAttributions({boldAttribution}),
          ),
          IconButton(
            icon: const Icon(Icons.format_italic, size: 20),
            tooltip: 'Italic',
            onPressed: () => _toggleAttributions({italicsAttribution}),
          ),
          IconButton(
            icon: const Icon(Icons.format_underline, size: 20),
            tooltip: 'Underline',
            onPressed: () => _toggleAttributions({underlineAttribution}),
          ),
          IconButton(
            icon: const Icon(Icons.format_strikethrough, size: 20),
            tooltip: 'Strikethrough',
            onPressed: () => _toggleAttributions({strikethroughAttribution}),
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
              tooltip: widget.pageViewMode
                  ? 'Switch to Standard View'
                  : 'Switch to Page View',
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

  void _toggleAttributions(Set<Attribution> attributions) {
    final selection = _composer.selection;
    if (selection == null || selection.isCollapsed) {
      _composer.preferences.toggleStyles(attributions);
      return;
    }

    _editor.execute([
      ToggleTextAttributionsRequest(
        documentRange: selection,
        attributions: attributions,
      ),
    ]);
  }

  void _showAddCommentDialog() {
    final selection = _composer.selection;
    if (selection == null || selection.isCollapsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select text to add a comment')),
      );
      return;
    }

    final range = selection.normalize(_document);
    final startOffset = _plainTextOffsetFromDocumentPosition(range.start);
    final endOffset = _plainTextOffsetFromDocumentPosition(range.end);

    showDialog(
      context: context,
      builder: (context) => NewCommentDialog(
        onCreate: (commentText, colorValue) {
          widget.onAddComment?.call(
            startOffset,
            endOffset,
            commentText,
            colorValue,
          );
        },
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final stylesheet = _buildEditorStylesheet(theme);

    final editor = Stack(
      children: [
        SuperEditor(
          editor: _editor,
          focusNode: _focusNode,
          autofocus: true,
          scrollController: _scrollController,
          documentLayoutKey: _documentLayoutKey,
          stylesheet: stylesheet,
          customStylePhases: _customStylePhases,
        ),
        if (_document.toPlainText().trim().isEmpty)
          Positioned(
            left: 0,
            top: 0,
            child: IgnorePointer(
              child: Text(
                'Start writing...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
      ],
    );

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: editor,
    );
  }

  Stylesheet _buildEditorStylesheet(ThemeData theme) {
    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 16,
      height: 1.5,
    );

    return defaultStylesheet.copyWith(
      documentPadding: EdgeInsets.zero,
      rules: [
        StyleRule(
          BlockSelector.all,
          (doc, docNode) => {
            Styles.maxWidth: double.infinity,
            Styles.padding: const CascadingPadding.all(0),
            Styles.textStyle: textStyle,
          },
        ),
      ],
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
    final plainText = _document.toPlainText();
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
    final base = _documentPositionFromPlainTextOffset(comment.startOffset);
    final extent = _documentPositionFromPlainTextOffset(comment.endOffset);

    _editor.execute([
      ChangeSelectionRequest(
        DocumentSelection(base: base, extent: extent),
        SelectionChangeType.expandSelection,
        SelectionReason.userInteraction,
      ),
    ]);

    _focusNode.requestFocus();
  }

  int _plainTextOffsetFromDocumentPosition(DocumentPosition position) {
    var offset = 0;
    for (final node in _document) {
      if (node is! TextNode) continue;

      if (node.id == position.nodeId) {
        final nodePosition = position.nodePosition;
        if (nodePosition is TextNodePosition) {
          return offset + nodePosition.offset;
        }
        return offset;
      }

      offset += node.text.length + 1; // node text + '\n'
    }

    return offset;
  }

  DocumentPosition _documentPositionFromPlainTextOffset(int plainTextOffset) {
    final safeOffset = plainTextOffset < 0 ? 0 : plainTextOffset;
    var runningOffset = 0;

    for (final node in _document) {
      if (node is! TextNode) continue;

      final nodeTextLength = node.text.length;
      final nodeStart = runningOffset;
      final nodeEnd = nodeStart + nodeTextLength;

      if (safeOffset <= nodeEnd) {
        final localOffset = (safeOffset - nodeStart).clamp(0, nodeTextLength);
        return DocumentPosition(
          nodeId: node.id,
          nodePosition: TextNodePosition(offset: localOffset),
        );
      }

      runningOffset += nodeTextLength + 1; // node text + '\n'
    }

    final lastTextNode =
        _document.lastWhere((node) => node is TextNode, orElse: () => _document.first) as TextNode;
    return DocumentPosition(
      nodeId: lastTextNode.id,
      nodePosition: TextNodePosition(offset: lastTextNode.text.length),
    );
  }
}
