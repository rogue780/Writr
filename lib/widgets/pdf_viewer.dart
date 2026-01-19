import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

import '../models/research_item.dart';

/// A widget for viewing PDF documents in-app.
class PdfViewer extends StatefulWidget {
  final ResearchItem item;
  final VoidCallback? onDownload;
  final VoidCallback? onOpenExternal;

  const PdfViewer({
    super.key,
    required this.item,
    this.onDownload,
    this.onOpenExternal,
  });

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  final pdfrx.PdfViewerController _controller = pdfrx.PdfViewerController();
  late pdfrx.PdfTextSearcher _textSearcher;
  VoidCallback? _removeTextSearcherListener;
  final TextEditingController _findController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  bool _showFindBar = false;

  int? _pageNumber;
  int? _pageCount;
  double? _zoom;

  @override
  void initState() {
    super.initState();
    _attachTextSearcher();
  }

  @override
  void didUpdateWidget(covariant PdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.fileSize != widget.item.fileSize ||
        oldWidget.item.modifiedAt != widget.item.modifiedAt) {
      _detachTextSearcher();
      _attachTextSearcher();
      _pageNumber = null;
      _pageCount = null;
      _zoom = null;
      _showFindBar = false;
      _findController.clear();
      _textSearcher.resetTextSearch();
    }
  }

  @override
  void dispose() {
    _detachTextSearcher();
    _findController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _attachTextSearcher() {
    _textSearcher = pdfrx.PdfTextSearcher(_controller);
    _removeTextSearcherListener = _textSearcher.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _detachTextSearcher() {
    _removeTextSearcherListener?.call();
    _removeTextSearcherListener = null;
    _textSearcher.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        const Divider(height: 1),
        if (_showFindBar) ...[
          _buildFindBar(context),
          const Divider(height: 1),
        ],
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 16,
            vertical: 8,
          ),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: isNarrow
              ? _buildNarrowToolbar(context, constraints.maxWidth)
              : _buildWideToolbar(context),
        );
      },
    );
  }

  Widget _buildWideToolbar(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.picture_as_pdf, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${widget.item.formattedFileSize} • PDF Document',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (_pageNumber != null && _pageCount != null) ...[
          Text(
            '${_pageNumber!}/${_pageCount!}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
        ],
        _toolbarIconButton(
          icon: Icons.chevron_left,
          tooltip: 'Previous page',
          onPressed: (_pageNumber == null || (_pageNumber ?? 1) <= 1)
              ? null
              : () => _goToPage((_pageNumber ?? 1) - 1),
        ),
        _toolbarIconButton(
          icon: Icons.chevron_right,
          tooltip: 'Next page',
          onPressed: (_pageNumber == null ||
                  _pageCount == null ||
                  (_pageNumber ?? 1) >= (_pageCount ?? 1))
              ? null
              : () => _goToPage((_pageNumber ?? 1) + 1),
        ),
        const VerticalDivider(width: 16),
        Text(
          '${((_zoom ?? 1.0) * 100).round()}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        _toolbarIconButton(
          icon: Icons.zoom_out,
          tooltip: 'Zoom out',
          onPressed: _pageCount == null ? null : _zoomOut,
        ),
        _toolbarIconButton(
          icon: Icons.zoom_in,
          tooltip: 'Zoom in',
          onPressed: _pageCount == null ? null : _zoomIn,
        ),
        _toolbarIconButton(
          icon: Icons.fit_screen,
          tooltip: 'Fit page',
          onPressed: _pageCount == null ? null : _fitPage,
        ),
        _toolbarIconButton(
          icon: _showFindBar ? Icons.close : Icons.search,
          tooltip: _showFindBar ? 'Close find' : 'Find in PDF',
          onPressed: _toggleFindBar,
        ),
        const VerticalDivider(width: 16),
        if (widget.onDownload != null)
          _toolbarIconButton(
            icon: Icons.download,
            tooltip: 'Download',
            onPressed: widget.onDownload,
          ),
        if (widget.onOpenExternal != null && !kIsWeb)
          _toolbarIconButton(
            icon: Icons.open_in_new,
            tooltip: 'Open in external viewer',
            onPressed: widget.onOpenExternal,
          ),
      ],
    );
  }

  Widget _buildNarrowToolbar(BuildContext context, double maxWidth) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildOverflowMenu(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _toolbarIconButton(
              icon: Icons.chevron_left,
              tooltip: 'Previous page',
              onPressed: (_pageNumber == null || (_pageNumber ?? 1) <= 1)
                  ? null
                  : () => _goToPage((_pageNumber ?? 1) - 1),
            ),
            Text(
              _pageNumber != null && _pageCount != null
                  ? '${_pageNumber!}/${_pageCount!}'
                  : '…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            _toolbarIconButton(
              icon: Icons.chevron_right,
              tooltip: 'Next page',
              onPressed: (_pageNumber == null ||
                      _pageCount == null ||
                      (_pageNumber ?? 1) >= (_pageCount ?? 1))
                  ? null
                  : () => _goToPage((_pageNumber ?? 1) + 1),
            ),
            const Spacer(),
            if (maxWidth >= 250)
              Text(
                '${((_zoom ?? 1.0) * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<_PdfToolbarAction>(
      tooltip: 'More',
      onSelected: (action) {
        switch (action) {
          case _PdfToolbarAction.find:
            _toggleFindBar();
            break;
          case _PdfToolbarAction.zoomIn:
            _zoomIn();
            break;
          case _PdfToolbarAction.zoomOut:
            _zoomOut();
            break;
          case _PdfToolbarAction.fitPage:
            _fitPage();
            break;
          case _PdfToolbarAction.download:
            widget.onDownload?.call();
            break;
          case _PdfToolbarAction.openExternal:
            widget.onOpenExternal?.call();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<_PdfToolbarAction>(
            value: _PdfToolbarAction.find,
            child: Row(
              children: [
                Icon(_showFindBar ? Icons.close : Icons.search, size: 18),
                const SizedBox(width: 8),
                Text(_showFindBar ? 'Close find' : 'Find in PDF'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<_PdfToolbarAction>(
            value: _PdfToolbarAction.zoomIn,
            enabled: _pageCount != null,
            child: const Row(
              children: [
                Icon(Icons.zoom_in, size: 18),
                SizedBox(width: 8),
                Text('Zoom in'),
              ],
            ),
          ),
          PopupMenuItem<_PdfToolbarAction>(
            value: _PdfToolbarAction.zoomOut,
            enabled: _pageCount != null,
            child: const Row(
              children: [
                Icon(Icons.zoom_out, size: 18),
                SizedBox(width: 8),
                Text('Zoom out'),
              ],
            ),
          ),
          PopupMenuItem<_PdfToolbarAction>(
            value: _PdfToolbarAction.fitPage,
            enabled: _pageCount != null,
            child: const Row(
              children: [
                Icon(Icons.fit_screen, size: 18),
                SizedBox(width: 8),
                Text('Fit page'),
              ],
            ),
          ),
          if (widget.onDownload != null) const PopupMenuDivider(),
          if (widget.onDownload != null)
            const PopupMenuItem<_PdfToolbarAction>(
              value: _PdfToolbarAction.download,
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
          if (widget.onOpenExternal != null && !kIsWeb)
            const PopupMenuItem<_PdfToolbarAction>(
              value: _PdfToolbarAction.openExternal,
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 18),
                  SizedBox(width: 8),
                  Text('Open external'),
                ],
              ),
            ),
        ];
      },
    );
  }

  Widget _toolbarIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
    );
  }

  void _toggleFindBar({bool? show}) {
    final shouldShow = show ?? !_showFindBar;

    setState(() {
      _showFindBar = shouldShow;
    });

    if (shouldShow) {
      Future.microtask(() {
        if (!mounted) return;
        _findFocusNode.requestFocus();
        _findController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _findController.text.length,
        );
      });

      final query = _findController.text;
      if (query.isNotEmpty) {
        _textSearcher.startTextSearch(
          query,
          caseInsensitive: true,
          goToFirstMatch: true,
          searchImmediately: true,
        );
      }
      return;
    }

    _textSearcher.resetTextSearch();
  }

  void _clearFind() {
    _findController.clear();
    _textSearcher.resetTextSearch();
    setState(() {});
    _findFocusNode.requestFocus();
  }

  void _onFindChanged(String value) {
    setState(() {});
    if (value.isEmpty) {
      _textSearcher.resetTextSearch();
      return;
    }

    _textSearcher.startTextSearch(
      value,
      caseInsensitive: true,
      goToFirstMatch: true,
    );
  }

  void _onFindSubmitted(String value) {
    if (value.isEmpty) return;

    final pattern = _textSearcher.pattern;
    if (pattern is String &&
        pattern == value &&
        _textSearcher.matches.isNotEmpty) {
      _textSearcher.goToNextMatch();
      return;
    }

    _textSearcher.startTextSearch(
      value,
      caseInsensitive: true,
      goToFirstMatch: true,
      searchImmediately: true,
    );
  }

  Widget _buildFindBar(BuildContext context) {
    final query = _findController.text;
    final matchCount = _textSearcher.matches.length;
    final currentIndex = _textSearcher.currentIndex;
    final currentMatchNumber = currentIndex != null ? currentIndex + 1 : 0;
    final isSearching = _textSearcher.isSearching;
    final progress = _textSearcher.searchProgress;

    final statusText = query.isEmpty
        ? 'Find in PDF'
        : matchCount == 0
            ? (isSearching ? 'Searching…' : 'No matches')
            : '$currentMatchNumber/$matchCount';

    final canNavigateMatches = matchCount > 0 && !isSearching;

    Widget iconAction({
      required IconData icon,
      required String tooltip,
      VoidCallback? onPressed,
    }) {
      return IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      );
    }

    final searchField = TextField(
      controller: _findController,
      focusNode: _findFocusNode,
      decoration: InputDecoration(
        hintText: 'Find in PDF',
        isDense: true,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.clear, size: 18),
                onPressed: _clearFind,
              ),
        border: const OutlineInputBorder(),
      ),
      onChanged: _onFindChanged,
      onSubmitted: _onFindSubmitted,
      textInputAction: TextInputAction.search,
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSearching)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress,
            ),
          ),
        if (isSearching) const SizedBox(width: 8),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        iconAction(
          icon: Icons.keyboard_arrow_up,
          tooltip: 'Previous match',
          onPressed: canNavigateMatches ? () => _textSearcher.goToPrevMatch() : null,
        ),
        iconAction(
          icon: Icons.keyboard_arrow_down,
          tooltip: 'Next match',
          onPressed: canNavigateMatches ? () => _textSearcher.goToNextMatch() : null,
        ),
        iconAction(
          icon: Icons.close,
          tooltip: 'Close find',
          onPressed: () => _toggleFindBar(show: false),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 520;
          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                searchField,
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: controls,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 8),
              controls,
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = widget.item.data;

    if (data == null || data.isEmpty) {
      return _buildNoDataPlaceholder(context);
    }

    if (!_looksLikePdf(data)) {
      return _buildLoadError(context, 'This file does not appear to be a valid PDF.');
    }

    return _buildPdf(context, data);
  }

  bool _looksLikePdf(Uint8List data) {
    return data.length > 4 &&
        data[0] == 0x25 && // %
        data[1] == 0x50 && // P
        data[2] == 0x44 && // D
        data[3] == 0x46; // F
  }

  String _sourceNameFor(ResearchItem item, Uint8List data) {
    final fileSize = item.fileSize ?? data.length;
    return 'research:${item.id}:$fileSize:${item.modifiedAt.millisecondsSinceEpoch}';
  }

  void _syncFromController({int? pageNumber}) {
    final currentPage = pageNumber ?? _controller.pageNumber;
    setState(() {
      _pageCount = _controller.pageCount;
      _pageNumber = currentPage;
      _zoom = _controller.currentZoom;
    });
  }

  Future<void> _goToPage(int pageNumber) async {
    if (_pageCount == null) return;
    final clamped = pageNumber.clamp(1, _pageCount!);
    await _controller.goToPage(pageNumber: clamped);
    if (!mounted) return;
    _syncFromController(pageNumber: clamped);
  }

  Future<void> _zoomIn() async {
    await _controller.zoomUp(loop: false);
    if (!mounted) return;
    _syncFromController();
  }

  Future<void> _zoomOut() async {
    await _controller.zoomDown(loop: false);
    if (!mounted) return;
    _syncFromController();
  }

  Future<void> _fitPage() async {
    final pageNumber = _controller.pageNumber ?? 1;
    final matrix = _controller.calcMatrixForFit(pageNumber: pageNumber);
    await _controller.goTo(matrix);
    if (!mounted) return;
    _syncFromController();
  }

  Widget _buildPdf(BuildContext context, Uint8List data) {
    final sourceName = _sourceNameFor(widget.item, data);

    return pdfrx.PdfViewer(
      pdfrx.PdfDocumentRefData(
        data,
        sourceName: sourceName,
        allowDataOwnershipTransfer: false,
      ),
      key: ValueKey(sourceName),
      controller: _controller,
      params: pdfrx.PdfViewerParams(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        enableTextSelection: true,
        pagePaintCallbacks: [_textSearcher.pageTextMatchPaintCallback],
        onViewerReady: (document, controller) {
          Future.microtask(() {
            if (!mounted) return;
            setState(() {
              _pageCount = document.pages.length;
              _pageNumber = controller.pageNumber ?? 1;
              _zoom = controller.currentZoom;
            });
          });
        },
        onPageChanged: (pageNumber) {
          if (!mounted || pageNumber == null || _pageCount == null) return;
          _syncFromController(pageNumber: pageNumber);
        },
        onInteractionEnd: (details) {
          if (!mounted || _pageCount == null) return;
          _syncFromController();
        },
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
          return const Center(child: CircularProgressIndicator());
        },
        errorBannerBuilder: (context, error, stackTrace, documentRef) {
          return _buildLoadError(context, error);
        },
      ),
    );
  }

  Widget _buildNoDataPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 80,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.item.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'PDF preview not available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 24),
          if (widget.onDownload != null)
            ElevatedButton.icon(
              onPressed: widget.onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadError(BuildContext context, Object error) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.formattedFileSize,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Unable to render PDF.\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.onDownload != null)
                        ElevatedButton.icon(
                          onPressed: widget.onDownload,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                      if (widget.onDownload != null &&
                          widget.onOpenExternal != null &&
                          !kIsWeb)
                        const SizedBox(width: 16),
                      if (widget.onOpenExternal != null && !kIsWeb)
                        OutlinedButton.icon(
                          onPressed: widget.onOpenExternal,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open External'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _PdfToolbarAction {
  find,
  zoomIn,
  zoomOut,
  fitPage,
  download,
  openExternal,
}

/// Placeholder for future PDF annotation support.
class PdfAnnotation {
  final String id;
  final int pageNumber;
  final Rect bounds;
  final PdfAnnotationType type;
  final String? text;
  final Color? color;

  PdfAnnotation({
    required this.id,
    required this.pageNumber,
    required this.bounds,
    required this.type,
    this.text,
    this.color,
  });
}

enum PdfAnnotationType {
  highlight,
  underline,
  strikethrough,
  note,
  freeText,
}
