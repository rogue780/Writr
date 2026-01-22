import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:super_editor/super_editor.dart';
import '../models/rtf_metadata.dart';
import '../models/scrivener_project.dart';
import '../services/dictionary_service.dart';
import '../services/preferences_service.dart';
import '../services/spell_check_service.dart';
import '../utils/rtf_attributed_text.dart';
import '../utils/scrivener_style_decoder.dart';
import 'spell_check_style_phase.dart';
import 'super_editor_style_phases.dart';

/// A specialized rich text editor for Scrivener mode that properly handles
/// RTF formatting round-trips.
///
/// This editor:
/// 1. Loads RTF content with full formatting preserved
/// 2. Displays bold, italic, underline, colors, etc.
/// 3. Saves changes back to RTF with formatting intact
class ScrivenerEditor extends StatefulWidget {
  final BinderItem item;
  final String rtfContent;
  final RtfMetadata? metadata;
  final Function(String rtfContent) onContentChanged;
  final Function(Document)? onDocumentChanged;
  final bool hasUnsavedChanges;
  final bool pageViewMode;
  final Function(bool)? onPageViewModeChanged;
  final bool isFullEditingUnlocked;

  const ScrivenerEditor({
    super.key,
    required this.item,
    required this.rtfContent,
    this.metadata,
    required this.onContentChanged,
    this.onDocumentChanged,
    this.hasUnsavedChanges = false,
    this.pageViewMode = false,
    this.onPageViewModeChanged,
    this.isFullEditingUnlocked = false,
  });

  @override
  State<ScrivenerEditor> createState() => ScrivenerEditorState();
}

class ScrivenerEditorState extends State<ScrivenerEditor> {
  late MutableDocument _document;
  late MutableDocumentComposer _composer;
  late Editor _editor;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  final _documentLayoutKey = GlobalKey();
  late final List<SingleColumnLayoutStylePhase> _customStylePhases;
  late final SuperEditorAndroidControlsController _androidControlsController;
  late final SuperEditorIosControlsController _iosControlsController;

  // Undo/redo history
  final List<String> undoStack = [];
  final List<String> redoStack = [];
  String _lastSavedContent = '';

  RtfMetadata _rtfMetadata = RtfMetadata.empty();
  // ignore: unused_field
  List<ScrivenerDecodedText>? _scrivenerTagData;
  bool _hasUnsavedChanges = false;
  bool _isInitializing = true;

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
    _customStylePhases = [
      ClampInvalidTextSelectionStylePhase(),
      _RtfFormattingStylePhase(),
    ];
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
        _customStylePhases.add(_spellCheckStylePhase!);
      });

      // Delay initial spell check to let UI render first
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _triggerSpellCheck();
      });
    } catch (e) {
      debugPrint('Spell check initialization failed: $e');
    }
  }

  void _onSpellCheckUpdate() {
    if (!mounted || _spellCheckStylePhase == null) return;
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

    // Clear history when loading new document
    undoStack.clear();
    redoStack.clear();

    // Convert RTF to AttributedText with formatting
    final converter = RtfToAttributedText(widget.rtfContent);
    var result = converter.convert();

    // Decode Scrivener style tags (e.g., <$Scr_Cs::2>) and apply formatting.
    // Note: These tags are display-only placeholders that Scrivener uses for
    // compile-time styling. We strip them for clean display but preserve
    // the data so we could potentially restore them on save.
    result = result.decodeScrivenerTags();

    _rtfMetadata = widget.metadata ?? result.metadata;
    // Store tag data for potential round-trip (currently informational only -
    // if text is edited, tags won't be restored as positions would be invalid)
    _scrivenerTagData = result.scrivenerTagData;

    // Create document from paragraphs
    _document = MutableDocument(
      nodes: [
        for (final paragraph in result.paragraphs)
          ParagraphNode(
            id: Editor.createNodeId(),
            text: paragraph,
          ),
      ],
    );

    // Ensure at least one node
    if (_document.isEmpty) {
      _document = MutableDocument.empty();
    }

    _composer = MutableDocumentComposer();
    _editor = createEditorWithoutLinkify(
      document: _document,
      composer: _composer,
    );

    // Store initial content for undo tracking
    _lastSavedContent = _getCurrentRtfContent();

    _document.addListener(_onDocumentChangeLog);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
    });
  }

  String _getCurrentRtfContent() {
    final paragraphs = <AttributedText>[];
    for (final node in _document) {
      if (node is TextNode) {
        paragraphs.add(node.text);
      }
    }
    final rtfConverter = AttributedTextToRtf(paragraphs, metadata: _rtfMetadata);
    return rtfConverter.convert();
  }

  @override
  void didUpdateWidget(ScrivenerEditor oldWidget) {
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

  bool _isUndoRedoOperation = false;

  void _onDocumentChangeLog(DocumentChangeLog changeLog) {
    if (_isInitializing) return;

    final rtfContent = _getCurrentRtfContent();

    // Track history for undo (but not if this change came from undo/redo)
    if (!_isUndoRedoOperation && _lastSavedContent != rtfContent) {
      undoStack.add(_lastSavedContent);
      redoStack.clear(); // Clear redo stack on new change
      // Limit undo stack size
      if (undoStack.length > 100) {
        undoStack.removeAt(0);
      }
      _lastSavedContent = rtfContent;
    }

    setState(() {
      _hasUnsavedChanges = true;
    });

    widget.onContentChanged(rtfContent);
    widget.onDocumentChanged?.call(_document);

    // Trigger spell check
    _triggerSpellCheck();
  }

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  /// Public method to perform undo - can be called from parent widget
  void undo() {
    if (!canUndo) return;

    final currentContent = _getCurrentRtfContent();
    redoStack.add(currentContent);

    final previousContent = undoStack.removeLast();
    _loadContentWithoutHistory(previousContent);
    _lastSavedContent = previousContent;

    widget.onContentChanged(previousContent);
  }

  /// Public method to perform redo - can be called from parent widget
  void redo() {
    if (!canRedo) return;

    final currentContent = _getCurrentRtfContent();
    undoStack.add(currentContent);

    final nextContent = redoStack.removeLast();
    _loadContentWithoutHistory(nextContent);
    _lastSavedContent = nextContent;

    widget.onContentChanged(nextContent);
  }

  void _loadContentWithoutHistory(String rtfContent) {
    _isUndoRedoOperation = true;

    // Remove listener temporarily
    _document.removeListener(_onDocumentChangeLog);

    // Convert RTF to AttributedText and decode Scrivener style tags
    final converter = RtfToAttributedText(rtfContent);
    final result = converter.convert().decodeScrivenerTags();

    // Clear and rebuild document
    while (_document.nodeCount > 0) {
      _document.deleteNodeAt(0);
    }

    for (final paragraph in result.paragraphs) {
      _document.insertNodeAt(
        _document.nodeCount,
        ParagraphNode(
          id: Editor.createNodeId(),
          text: paragraph,
        ),
      );
    }

    // Ensure at least one node
    if (_document.isEmpty) {
      _document.insertNodeAt(
        0,
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText(''),
        ),
      );
    }

    // Re-add listener
    _document.addListener(_onDocumentChangeLog);

    _isUndoRedoOperation = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Keyboard shortcuts (Ctrl+Z, Ctrl+Y) are handled at the parent level
    // via CallbackShortcuts in project_editor_screen.dart
    return Container(
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          if (widget.item.type == BinderItemType.text) _buildToolbar(context),
          Expanded(
            child: widget.item.type == BinderItemType.text
                ? _buildEditor(context)
                : _buildNonEditableView(context),
          ),
          if (widget.item.type == BinderItemType.text) _buildStatusBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isUnlocked = widget.isFullEditingUnlocked;
    final backgroundColor = isUnlocked
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.amber.withValues(alpha: 0.1);
    final borderColor = isUnlocked ? Colors.green.shade300 : Colors.amber.shade300;
    final iconColor = isUnlocked ? Colors.green.shade700 : Colors.amber.shade700;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUnlocked ? Icons.lock_open : Icons.lock_outline,
            size: 20,
            color: iconColor,
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
          // Scrivener mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isUnlocked ? Colors.green.shade700 : Colors.amber.shade700,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  size: 12,
                  color: isUnlocked ? Colors.green.shade800 : Colors.amber.shade800,
                ),
                const SizedBox(width: 4),
                Text(
                  'RTF Mode',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isUnlocked ? Colors.green.shade800 : Colors.amber.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: Theme.of(context).dividerColor,
          ),
          // Superscript/subscript
          IconButton(
            icon: const Icon(Icons.superscript, size: 20),
            tooltip: 'Superscript',
            onPressed: () => _toggleAttributions({superscriptAttribution}),
            constraints: iconButtonConstraints,
          ),
          IconButton(
            icon: const Icon(Icons.subscript, size: 20),
            tooltip: 'Subscript',
            onPressed: () => _toggleAttributions({subscriptAttribution}),
            constraints: iconButtonConstraints,
          ),
          // Spacer to push page view to the right
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
          const SizedBox(width: 16),
          // RTF info
          Icon(Icons.info_outline, size: 14, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            'Fonts: ${_rtfMetadata.fontTable.length}, Colors: ${_rtfMetadata.colorTable.length}',
            style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
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
    );
  }

  Widget _buildIosSelectionToolbar(
    BuildContext context,
    Key mobileToolbarKey,
    Object focalPoint,
  ) {
    if (kIsWeb) {
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
    );
  }
}

/// Style phase that applies RTF-specific attributions to text rendering.
///
/// This handles custom RTF attributions (font size, text color, background color,
/// font family, superscript, subscript) that aren't part of SuperEditor's default
/// attribution set.
class _RtfFormattingStylePhase extends SingleColumnLayoutStylePhase {
  @override
  SingleColumnLayoutViewModel style(
    Document document,
    SingleColumnLayoutViewModel viewModel,
  ) {
    return SingleColumnLayoutViewModel(
      padding: viewModel.padding,
      componentViewModels: [
        for (final componentViewModel in viewModel.componentViewModels)
          _styleComponent(componentViewModel),
      ],
    );
  }

  SingleColumnLayoutComponentViewModel _styleComponent(
    SingleColumnLayoutComponentViewModel viewModel,
  ) {
    if (viewModel is! TextComponentViewModel) {
      return viewModel;
    }

    // SuperEditor's default stylesheet handles bold, italic, underline, strikethrough.
    // We need to add styling for our RTF-specific attributions.
    // For now, this is a placeholder - the actual styling would need to be done
    // by adding custom style rules to the stylesheet or using a custom text component.
    //
    // TODO: Implement custom styling for:
    // - RtfFontSizeAttribution
    // - RtfTextColorAttribution
    // - RtfBackgroundColorAttribution
    // - RtfFontFamilyAttribution
    // - rtfSuperscriptAttribution
    // - rtfSubscriptAttribution

    return viewModel;
  }
}

/// Mobile selection toolbar for cut/copy/paste operations.
class _MobileSelectionToolbar extends StatelessWidget {
  const _MobileSelectionToolbar({
    super.key,
    required this.selectionNotifier,
    required this.onCut,
    required this.onCopy,
    required this.onPaste,
    required this.onSelectAll,
  });

  final ValueListenable<DocumentSelection?> selectionNotifier;
  final VoidCallback onCut;
  final VoidCallback onCopy;
  final VoidCallback onPaste;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: selectionNotifier,
      builder: (context, selection, child) {
        final hasExpandedSelection = selection != null && !selection.isCollapsed;

        final actions = <_MobileToolbarAction>[
          if (hasExpandedSelection)
            _MobileToolbarAction(label: 'Cut', onPressed: onCut),
          if (hasExpandedSelection)
            _MobileToolbarAction(label: 'Copy', onPressed: onCopy),
          _MobileToolbarAction(label: 'Paste', onPressed: onPaste),
          _MobileToolbarAction(label: 'Select All', onPressed: onSelectAll),
        ];

        return Material(
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surfaceContainerHighest,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Wrap(
              children: [
                for (final action in actions)
                  TextButton(
                    onPressed: action.onPressed,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
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

class _MobileToolbarAction {
  const _MobileToolbarAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}
