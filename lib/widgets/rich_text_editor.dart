import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:super_editor/super_editor.dart';
import '../models/comment.dart';
import '../models/scrivener_project.dart';
import '../services/dictionary_service.dart';
import '../services/preferences_service.dart';
import '../services/spell_check_service.dart';
import '../utils/super_editor_markdown.dart';
import 'comment_bubble.dart';
import 'spell_check_style_phase.dart';
import 'super_editor_style_phases.dart';

/// Rich text editor widget using SuperEditor for formatting support.
class RichTextEditor extends StatefulWidget {
  final BinderItem item;
  final String content;
  final bool useMarkdown;
  final Function(String) onContentChanged;
  final Function(Document)? onDocumentChanged;
  final bool hasUnsavedChanges;
  final List<DocumentComment> comments;
  final Function(int startOffset, int endOffset, String text, int color)?
      onAddComment;
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
    this.useMarkdown = false,
    required this.onContentChanged,
    this.onDocumentChanged,
    this.hasUnsavedChanges = false,
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
  State<RichTextEditor> createState() => RichTextEditorState();
}

class RichTextEditorState extends State<RichTextEditor> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  final _documentLayoutKey = GlobalKey();
  late final List<SingleColumnLayoutStylePhase> _customStylePhases;
  late final SuperEditorAndroidControlsController _androidControlsController;
  late final SuperEditorIosControlsController _iosControlsController;

  bool _hasUnsavedChanges = false;
  bool _isInitializing = true;
  String? _selectedCommentId;
  late bool _showCommentMargin;

  // Undo/redo history
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  String _lastSavedContent = '';
  static const int _maxHistorySize = 100;

  // Page view settings
  static const double _pageMaxWidth = 800.0;
  static const double _pageMinMargin = 40.0;

  // Spell check
  SpellCheckService? _spellCheckService;
  SpellCheckStylePhase? _spellCheckStylePhase;
  bool _spellCheckInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _androidControlsController = SuperEditorAndroidControlsController(
      toolbarBuilder: _buildAndroidSelectionToolbar,
    );
    _iosControlsController = SuperEditorIosControlsController(
      toolbarBuilder: _buildIosSelectionToolbar,
    );
    _customStylePhases = [ClampInvalidTextSelectionStylePhase()];
    _showCommentMargin = widget.showCommentMargin;
    _initializeEditor();
    _initSpellCheck();
  }

  Future<void> _initSpellCheck() async {
    try {
      final dictionary = await DictionaryService.getInstance();
      if (!mounted) return;

      _spellCheckService = SpellCheckService(dictionary);
      _spellCheckStylePhase = SpellCheckStylePhase(
        spellCheckService: _spellCheckService!,
        enabled: true,
      );

      // Listen for spell check updates
      _spellCheckService!.addListener(_onSpellCheckUpdate);

      setState(() {
        _spellCheckInitialized = true;
        // Add spell check phase to custom phases
        _customStylePhases.add(_spellCheckStylePhase!);
      });

      // Delay initial spell check to let UI render first
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _triggerSpellCheck();
      });
    } catch (e) {
      // Spell check initialization failed - continue without it
      debugPrint('Spell check initialization failed: $e');
    }
  }

  void _onSpellCheckUpdate() {
    if (!mounted || _spellCheckStylePhase == null) return;

    // Sync errors to the style phase and trigger rebuild
    _spellCheckStylePhase!.syncErrors(_document);
    setState(() {});
  }

  void _triggerSpellCheck() {
    if (_spellCheckService == null || !_spellCheckInitialized) return;

    final text = _document.toPlainText();
    _spellCheckService!.checkText(text);
  }

  void _initializeEditor() {
    _isInitializing = true;
    _document = _createDocumentFromContent(widget.content);
    _composer = MutableDocumentComposer();
    _editor = createEditorWithoutLinkify(
      document: _document,
      composer: _composer,
    );

    _document.addListener(_onDocumentChangeLog);

    // Initialize undo history with current content
    _lastSavedContent = widget.content;
    _undoStack.clear();
    _redoStack.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    });
  }

  MutableDocument _createDocumentFromContent(String content) {
    if (widget.useMarkdown) {
      return createDocumentFromMarkdown(content);
    }

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

    if (oldWidget.hasUnsavedChanges && !widget.hasUnsavedChanges) {
      if (_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = false;
        });
      }
    }

    if (oldWidget.showCommentMargin != widget.showCommentMargin) {
      _showCommentMargin = widget.showCommentMargin;
    }
  }

  @override
  void dispose() {
    _document.removeListener(_onDocumentChangeLog);
    _spellCheckService?.removeListener(_onSpellCheckUpdate);
    _spellCheckService?.dispose();
    _document.dispose();
    _composer.dispose();
    _androidControlsController.dispose();
    _iosControlsController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onDocumentChangeLog(DocumentChangeLog changeLog) {
    if (_isInitializing) return;

    final newContent = widget.useMarkdown
        ? markdownFromDocument(_document)
        : _document.toPlainText();

    // Track undo history - save the previous state before this change
    if (_lastSavedContent != newContent) {
      _undoStack.add(_lastSavedContent);
      if (_undoStack.length > _maxHistorySize) {
        _undoStack.removeAt(0);
      }
      // Clear redo stack when new changes are made
      _redoStack.clear();
      _lastSavedContent = newContent;
    }

    setState(() {
      _hasUnsavedChanges = true;
    });

    widget.onContentChanged(newContent);
    widget.onDocumentChanged?.call(_document);

    // Trigger spell check
    _triggerSpellCheck();
  }

  /// Whether undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether redo is available
  bool get canRedo => _redoStack.isNotEmpty;

  /// Public method to perform undo - can be called from parent widget
  void undo() {
    if (!canUndo) return;

    // Save current content to redo stack
    final currentContent = widget.useMarkdown
        ? markdownFromDocument(_document)
        : _document.toPlainText();
    _redoStack.add(currentContent);

    // Get previous content from undo stack
    final previousContent = _undoStack.removeLast();

    // Load previous content without triggering history tracking
    _loadContentWithoutHistory(previousContent);

    // Update last saved content
    _lastSavedContent = previousContent;

    // Notify parent of content change
    widget.onContentChanged(previousContent);
  }

  /// Public method to perform redo - can be called from parent widget
  void redo() {
    if (!canRedo) return;

    // Save current content to undo stack
    final currentContent = widget.useMarkdown
        ? markdownFromDocument(_document)
        : _document.toPlainText();
    _undoStack.add(currentContent);

    // Get next content from redo stack
    final nextContent = _redoStack.removeLast();

    // Load next content without triggering history tracking
    _loadContentWithoutHistory(nextContent);

    // Update last saved content
    _lastSavedContent = nextContent;

    // Notify parent of content change
    widget.onContentChanged(nextContent);
  }

  /// Load content without adding to undo history
  void _loadContentWithoutHistory(String content) {
    _isInitializing = true;

    // Remove listener before modifying document
    _document.removeListener(_onDocumentChangeLog);

    // Store old document/composer for deferred disposal
    final oldDocument = _document;
    final oldComposer = _composer;

    // Create new document with the content
    _document = _createDocumentFromContent(content);
    _composer = MutableDocumentComposer();
    _editor = createEditorWithoutLinkify(
      document: _document,
      composer: _composer,
    );

    // Re-add listener
    _document.addListener(_onDocumentChangeLog);

    _isInitializing = false;

    setState(() {
      _hasUnsavedChanges = true;
    });

    // Dispose old document/composer after the frame completes
    // to avoid issues with focus handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldDocument.dispose();
      oldComposer.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompact = _isCompactLayout(context);
    final showSideComments =
        !isCompact && _showCommentMargin && widget.comments.isNotEmpty;

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
                      if (showSideComments) _buildCommentMargin(context),
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
    // Use constrained IconButtons with 48dp touch targets (Material Design guideline)
    const iconButtonConstraints = BoxConstraints(
      minWidth: 40,
      minHeight: 40,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Undo/Redo buttons
          IconButton(
            icon: Icon(
              Icons.undo,
              size: 20,
              color: canUndo ? null : Theme.of(context).disabledColor,
            ),
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: canUndo ? undo : null,
            constraints: iconButtonConstraints,
          ),
          IconButton(
            icon: Icon(
              Icons.redo,
              size: 20,
              color: canRedo ? null : Theme.of(context).disabledColor,
            ),
            tooltip: 'Redo (Ctrl+Y)',
            onPressed: canRedo ? redo : null,
            constraints: iconButtonConstraints,
          ),
          // Divider after undo/redo
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Theme.of(context).dividerColor,
          ),
          // Formatting buttons
          IconButton(
            icon: const Icon(Icons.format_bold, size: 20),
            tooltip: 'Bold',
            onPressed: () => _toggleAttributions({boldAttribution}),
            constraints: iconButtonConstraints,
          ),
          IconButton(
            icon: const Icon(Icons.format_italic, size: 20),
            tooltip: 'Italic',
            onPressed: () => _toggleAttributions({italicsAttribution}),
            constraints: iconButtonConstraints,
          ),
          IconButton(
            icon: const Icon(Icons.format_underline, size: 20),
            tooltip: 'Underline',
            onPressed: () => _toggleAttributions({underlineAttribution}),
            constraints: iconButtonConstraints,
          ),
          IconButton(
            icon: const Icon(Icons.format_strikethrough, size: 20),
            tooltip: 'Strikethrough',
            onPressed: () => _toggleAttributions({strikethroughAttribution}),
            constraints: iconButtonConstraints,
          ),
          // Spacer to push page view and comments to the right
          const Spacer(),
          // Page view toggle (right-justified)
          IconButton(
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
            constraints: iconButtonConstraints,
          ),
          // Add comment button (right-justified)
          if (widget.onAddComment != null)
            IconButton(
              icon: const Icon(Icons.add_comment, size: 20),
              onPressed: _showAddCommentDialog,
              tooltip: 'Add Comment',
              constraints: iconButtonConstraints,
            ),
          // Comments panel toggle (right-justified)
          if (widget.comments.isNotEmpty) _buildCommentsButton(context),
        ],
      ),
    );
  }

  bool _isCompactLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide < 600;
  }

  Widget _buildCommentsButton(BuildContext context) {
    final isCompact = _isCompactLayout(context);
    final isVisible = !isCompact && _showCommentMargin;
    final count = widget.comments.length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            isVisible ? Icons.comment : Icons.comment_outlined,
            size: 20,
          ),
          tooltip: isCompact
              ? 'Comments'
              : (isVisible ? 'Hide Comments' : 'Show Comments'),
          onPressed: _toggleComments,
          color: isVisible ? Theme.of(context).colorScheme.primary : null,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _toggleComments() {
    if (widget.comments.isEmpty) {
      return;
    }

    if (_isCompactLayout(context)) {
      _showCommentsBottomSheet();
      return;
    }

    setState(() {
      _showCommentMargin = !_showCommentMargin;
    });
  }

  Future<void> _showCommentsBottomSheet() async {
    if (widget.comments.isEmpty) {
      return;
    }

    var sheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        return StatefulBuilder(
          builder: (sheetContext, sheetSetState) {
            final sortedComments = [...widget.comments]
              ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

            void refreshAfterFrame() {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !sheetOpen) return;
                sheetSetState(() {});
              });
            }

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottomInset),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.sizeOf(sheetContext).height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(sheetContext).dividerColor,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.comment, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Comments (${widget.comments.length})',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(sheetContext).pop(),
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
                                Navigator.of(sheetContext).pop();
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!mounted) return;
                                  _navigateToComment(comment);
                                });
                              },
                              onResolve: widget.onResolveComment != null
                                  ? () {
                                      widget.onResolveComment!(
                                        comment.id,
                                        !comment.isResolved,
                                      );
                                      refreshAfterFrame();
                                    }
                                  : null,
                              onDelete: widget.onDeleteComment != null
                                  ? () {
                                      widget.onDeleteComment!(comment.id);
                                      refreshAfterFrame();
                                    }
                                  : null,
                              onReply: widget.onReplyToComment != null
                                  ? (text) {
                                      widget.onReplyToComment!(
                                          comment.id, text);
                                      refreshAfterFrame();
                                    }
                                  : null,
                              onEdit: widget.onEditComment != null
                                  ? (text) {
                                      widget.onEditComment!(comment.id, text);
                                      refreshAfterFrame();
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    sheetOpen = false;
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

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_isCompactLayout(this.context)) {
              _showCommentsBottomSheet();
              return;
            }
            setState(() {
              _showCommentMargin = true;
            });
          });
        },
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final stylesheet = _buildEditorStylesheet(theme);

    // Update spell check enabled state from preferences
    final prefs = context.watch<PreferencesService>();
    _spellCheckStylePhase?.setEnabled(prefs.spellCheckEnabled);

    final editor = Stack(
      children: [
        SuperEditorAndroidControlsScope(
          controller: _androidControlsController,
          child: SuperEditorIosControlsScope(
            controller: _iosControlsController,
            child: SuperEditor(
              editor: _editor,
              focusNode: _focusNode,
              autofocus: true,
              scrollController: _scrollController,
              documentLayoutKey: _documentLayoutKey,
              stylesheet: stylesheet,
              customStylePhases: _customStylePhases,
              selectionStyle: SelectionStyles(
                selectionColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              documentOverlayBuilders: [
                DefaultCaretOverlayBuilder(
                  caretStyle: CaretStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
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
      final isDarkMode = theme.brightness == Brightness.dark;
      final backgroundColor = isDarkMode
          ? theme.colorScheme.surfaceContainerLow
          : Colors.grey[300];
      final pageColor = isDarkMode
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.white;

      return Container(
        color: backgroundColor,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: _pageMaxWidth),
            margin: const EdgeInsets.symmetric(
              horizontal: _pageMinMargin,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              color: pageColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.15),
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Hide Comments',
                  onPressed: () {
                    setState(() {
                      _showCommentMargin = false;
                    });
                  },
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

    final lastTextNode = _document.lastWhere((node) => node is TextNode,
        orElse: () => _document.first) as TextNode;
    return DocumentPosition(
      nodeId: lastTextNode.id,
      nodePosition: TextNodePosition(offset: lastTextNode.text.length),
    );
  }

  CommonEditorOperations _createCommonEditorOperations() {
    return CommonEditorOperations(
      document: _document,
      editor: _editor,
      composer: _composer,
      documentLayoutResolver: () =>
          _documentLayoutKey.currentState as DocumentLayout,
    );
  }

  Widget _buildAndroidSelectionToolbar(
    BuildContext context,
    Key mobileToolbarKey,
    Object focalPoint,
  ) {
    if (kIsWeb) {
      // On web, we defer to the browser's internal overlay controls for mobile.
      return const SizedBox();
    }

    return _MobileSelectionToolbar(
      key: mobileToolbarKey,
      selectionNotifier: _composer.selectionNotifier,
      onCut: () {
        _createCommonEditorOperations().cut();
        _androidControlsController.hideToolbar();
      },
      onCopy: () {
        _createCommonEditorOperations().copy();
        _androidControlsController.hideToolbar();
      },
      onPaste: () {
        _createCommonEditorOperations().paste();
        _androidControlsController.hideToolbar();
      },
      onSelectAll: () {
        _createCommonEditorOperations().selectAll();
      },
      onAddComment: widget.onAddComment == null
          ? null
          : () {
              _androidControlsController.hideToolbar();
              _showAddCommentDialog();
            },
    );
  }

  Widget _buildIosSelectionToolbar(
    BuildContext context,
    Key mobileToolbarKey,
    Object focalPoint,
  ) {
    if (kIsWeb) {
      // On web, we defer to the browser's internal overlay controls for mobile.
      return const SizedBox();
    }

    return _MobileSelectionToolbar(
      key: mobileToolbarKey,
      selectionNotifier: _composer.selectionNotifier,
      onCut: () {
        _createCommonEditorOperations().cut();
        _iosControlsController.hideToolbar();
      },
      onCopy: () {
        _createCommonEditorOperations().copy();
        _iosControlsController.hideToolbar();
      },
      onPaste: () {
        _createCommonEditorOperations().paste();
        _iosControlsController.hideToolbar();
      },
      onSelectAll: () {
        _createCommonEditorOperations().selectAll();
      },
      onAddComment: widget.onAddComment == null
          ? null
          : () {
              _iosControlsController.hideToolbar();
              _showAddCommentDialog();
            },
    );
  }
}

class _MobileSelectionToolbar extends StatelessWidget {
  const _MobileSelectionToolbar({
    super.key,
    required this.selectionNotifier,
    required this.onCut,
    required this.onCopy,
    required this.onPaste,
    required this.onSelectAll,
    this.onAddComment,
  });

  final ValueListenable<DocumentSelection?> selectionNotifier;
  final VoidCallback onCut;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onSelectAll;
  final VoidCallback? onAddComment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: selectionNotifier,
      builder: (context, selection, child) {
        final hasExpandedSelection =
            selection != null && !selection.isCollapsed;

        final actions = <_MobileSelectionToolbarAction>[
          if (hasExpandedSelection)
            _MobileSelectionToolbarAction(
              label: 'Cut',
              onPressed: onCut,
            ),
          if (hasExpandedSelection)
            _MobileSelectionToolbarAction(
              label: 'Copy',
              onPressed: onCopy,
            ),
          if (hasExpandedSelection && onAddComment != null)
            _MobileSelectionToolbarAction(
              label: 'Comment',
              onPressed: onAddComment!,
            ),
          _MobileSelectionToolbarAction(
            label: 'Paste',
            onPressed: onPaste,
          ),
          _MobileSelectionToolbarAction(
            label: 'Select All',
            onPressed: onSelectAll,
          ),
        ];

        return Material(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surfaceContainerHighest,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Wrap(
              spacing: 0,
              runSpacing: 0,
              children: [
                for (final action in actions)
                  TextButton(
                    onPressed: action.onPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(action.label),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileSelectionToolbarAction {
  const _MobileSelectionToolbarAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}
