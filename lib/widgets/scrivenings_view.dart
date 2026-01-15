import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../models/scrivener_project.dart';

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
  final Map<String, QuillController> _controllers = {};
  final ScrollController _scrollController = ScrollController();
  String? _activeDocumentId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final item in _getDocuments()) {
      final content = widget.textContents[item.id] ?? '';
      final document = Document();
      if (content.isNotEmpty) {
        document.insert(0, content);
      }

      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );

      controller.addListener(() {
        _onControllerChanged(item.id, controller);
      });

      _controllers[item.id] = controller;
    }
  }

  void _onControllerChanged(String documentId, QuillController controller) {
    final plainText = controller.document.toPlainText();
    widget.onContentChanged(documentId, plainText);
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
    // Recursively get all text documents from the folder
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
            '• $totalWords words',
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        final controller = _controllers[document.id];

        if (controller == null) return const SizedBox.shrink();

        return _buildDocumentSection(context, document, controller, index);
      },
    );
  }

  Widget _buildDocumentSection(
    BuildContext context,
    BinderItem document,
    QuillController controller,
    int index,
  ) {
    final isActive = _activeDocumentId == document.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Document header/separator
        GestureDetector(
          onTap: () => widget.onDocumentTapped?.call(document),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: EdgeInsets.only(top: index > 0 ? 24 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
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
        const SizedBox(height: 8),
        // Document editor
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              setState(() {
                _activeDocumentId = document.id;
              });
            }
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: QuillEditor.basic(
              controller: controller,
              config: QuillEditorConfig(
                placeholder: 'Start writing in ${document.title}...',
                minHeight: 80,
                autoFocus: false,
                expands: false,
                scrollable: false,
              ),
            ),
          ),
        ),
        // Section divider (except for last item)
        if (index < _getDocuments().length - 1)
          Padding(
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
      ],
    );
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}
