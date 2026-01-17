import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import '../models/scrivener_project.dart';
import 'super_editor_style_phases.dart';

/// Scrivenings view displaying multiple documents as one continuous text.
class ScriveningsView extends StatefulWidget {
  final BinderItem folder;
  final Map<String, String> textContents;
  final Function(String, String) onContentChanged;
  final Function(BinderItem)? onDocumentTapped;

  const ScriveningsView({
    super.key,
    required this.folder,
    required this.textContents,
    required this.onContentChanged,
    this.onDocumentTapped,
  });

  @override
  State<ScriveningsView> createState() => _ScriveningsViewState();
}

class _ScriveningsViewState extends State<ScriveningsView> {
  final Map<String, _ScriveningsEditorController> _controllers = {};
  final ScrollController _scrollController = ScrollController();
  String? _activeDocumentId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final item in _getDocuments()) {
      final documentId = item.id;
      final content = widget.textContents[documentId] ?? '';

      final document = _createDocumentFromContent(content);
      final composer = MutableDocumentComposer();
      final editor = createDefaultDocumentEditor(
        document: document,
        composer: composer,
      );

      void listener(DocumentChangeLog changeLog) {
        widget.onContentChanged(documentId, document.toPlainText());
      }
      document.addListener(listener);

      final focusNode = FocusNode();
      void focusListener() {
        if (!mounted) return;
        if (!focusNode.hasFocus) return;
        setState(() {
          _activeDocumentId = documentId;
        });
      }
      focusNode.addListener(focusListener);

      _controllers[documentId] = _ScriveningsEditorController(
        document: document,
        composer: composer,
        editor: editor,
        documentListener: listener,
        focusNode: focusNode,
        focusListener: focusListener,
        customStylePhases: [ClampInvalidTextSelectionStylePhase()],
      );
    }
  }

  MutableDocument _createDocumentFromContent(String content) {
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    var lines = normalized.split('\n');

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
  void didUpdateWidget(ScriveningsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.folder.id != widget.folder.id) {
      _disposeControllers();
      _initializeControllers();
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    _scrollController.dispose();
    super.dispose();
  }

  List<BinderItem> _getDocuments() {
    final documents = <BinderItem>[];
    _collectDocuments(widget.folder.children, documents);
    return documents;
  }

  void _collectDocuments(List<BinderItem> items, List<BinderItem> documents) {
    for (final item in items) {
      if (item.type == BinderItemType.text) {
        documents.add(item);
      }
      if (item.children.isNotEmpty) {
        _collectDocuments(item.children, documents);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = _getDocuments();

    return Column(
      children: [
        _buildToolbar(context, documents),
        Expanded(
          child: documents.isEmpty
              ? _buildEmptyState(context)
              : _buildScriveningsEditor(context, documents),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, List<BinderItem> documents) {
    final totalWords = documents.fold<int>(0, (sum, doc) {
      final content = widget.textContents[doc.id] ?? '';
      return sum + _countWords(content);
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.article, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Scrivenings: ${widget.folder.title}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Text(
            '${documents.length} documents',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(width: 8),
          Text(
            'ƒ?› $totalWords words',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Spacer(),
          if (_activeDocumentId != null)
            Text(
              'Editing: ${_getDocumentTitle(_activeDocumentId!)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  String _getDocumentTitle(String documentId) {
    for (final doc in _getDocuments()) {
      if (doc.id == documentId) return doc.title;
    }
    return 'Unknown';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No documents to display',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add documents to this folder to edit them together',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriveningsEditor(
    BuildContext context,
    List<BinderItem> documents,
  ) {
    final theme = Theme.of(context);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        for (var index = 0; index < documents.length; index++)
          ..._buildDocumentSlivers(
            context: context,
            theme: theme,
            document: documents[index],
            controller: _controllers[documents[index].id],
            index: index,
            totalDocuments: documents.length,
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  List<Widget> _buildDocumentSlivers({
    required BuildContext context,
    required ThemeData theme,
    required BinderItem document,
    required _ScriveningsEditorController? controller,
    required int index,
    required int totalDocuments,
  }) {
    if (controller == null) return const [];

    final isActive = _activeDocumentId == document.id;

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () => widget.onDocumentTapped?.call(document),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.only(top: index > 0 ? 24 : 0),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isActive ? theme.colorScheme.primary : theme.dividerColor,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    document.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '${_countWords(widget.textContents[document.id] ?? '')} words',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SuperEditor(
          editor: controller.editor,
          focusNode: controller.focusNode,
          stylesheet: _buildEditorStylesheet(theme),
          customStylePhases: controller.customStylePhases,
        ),
      ),
      if (index < totalDocuments - 1)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.more_horiz,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
          ),
        ),
    ];
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

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}

class _ScriveningsEditorController {
  _ScriveningsEditorController({
    required this.document,
    required this.composer,
    required this.editor,
    required this.documentListener,
    required this.focusNode,
    required this.focusListener,
    required this.customStylePhases,
  });

  final MutableDocument document;
  final MutableDocumentComposer composer;
  final Editor editor;
  final DocumentChangeListener documentListener;
  final FocusNode focusNode;
  final VoidCallback focusListener;
  final List<SingleColumnLayoutStylePhase> customStylePhases;

  void dispose() {
    document.removeListener(documentListener);
    document.dispose();
    composer.dispose();
    focusNode.removeListener(focusListener);
    focusNode.dispose();
  }
}
