import 'package:flutter/material.dart';
import '../models/editor_state.dart';
import '../models/research_item.dart';
import '../models/scrivener_project.dart';
import 'research_viewer.dart';
import 'rich_text_editor.dart';

/// A split editor widget that displays two editor panes side by side or stacked.
class SplitEditor extends StatefulWidget {
  final SplitEditorState state;
  final Map<String, String> textContents;
  final Map<String, ResearchItem> researchItems;
  final bool useMarkdown;
  final bool pageViewMode;
  final ValueChanged<bool>? onPageViewModeChanged;
  final bool hasUnsavedChanges;
  final Function(String, String) onContentChanged;
  final Function(SplitEditorState) onStateChanged;

  const SplitEditor({
    super.key,
    required this.state,
    required this.textContents,
    required this.researchItems,
    this.useMarkdown = false,
    this.pageViewMode = false,
    this.onPageViewModeChanged,
    this.hasUnsavedChanges = false,
    required this.onContentChanged,
    required this.onStateChanged,
  });

  @override
  State<SplitEditor> createState() => _SplitEditorState();
}

class _SplitEditorState extends State<SplitEditor> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.state.isSplitEnabled) {
      // Single pane mode
      return _buildEditorPane(
        widget.state.primaryPane,
        isPrimary: true,
        showBorder: false,
      );
    }

    // Split mode
    return widget.state.orientation == SplitOrientation.vertical
        ? _buildVerticalSplit(context)
        : _buildHorizontalSplit(context);
  }

  Widget _buildVerticalSplit(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final primaryWidth = constraints.maxWidth * widget.state.splitPosition;
        final secondaryWidth =
            constraints.maxWidth * (1 - widget.state.splitPosition);

        return Row(
          children: [
            // Primary pane (left)
            SizedBox(
              width: primaryWidth - 4,
              child: _buildEditorPane(
                widget.state.primaryPane,
                isPrimary: true,
              ),
            ),
            // Resizable divider
            _buildDivider(context, isVertical: true),
            // Secondary pane (right)
            SizedBox(
              width: secondaryWidth - 4,
              child: _buildEditorPane(
                widget.state.secondaryPane,
                isPrimary: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalSplit(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final primaryHeight =
            constraints.maxHeight * widget.state.splitPosition;
        final secondaryHeight =
            constraints.maxHeight * (1 - widget.state.splitPosition);

        return Column(
          children: [
            // Primary pane (top)
            SizedBox(
              height: primaryHeight - 4,
              child: _buildEditorPane(
                widget.state.primaryPane,
                isPrimary: true,
              ),
            ),
            // Resizable divider
            _buildDivider(context, isVertical: false),
            // Secondary pane (bottom)
            SizedBox(
              height: secondaryHeight - 4,
              child: _buildEditorPane(
                widget.state.secondaryPane,
                isPrimary: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context, {required bool isVertical}) {
    return MouseRegion(
      cursor: isVertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          _handleDrag(details, isVertical);
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Container(
          width: isVertical ? 8 : double.infinity,
          height: isVertical ? double.infinity : 8,
          color: _isDragging
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
          child: Center(
            child: Container(
              width: isVertical ? 2 : 40,
              height: isVertical ? 40 : 2,
              decoration: BoxDecoration(
                color: _isDragging
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDrag(DragUpdateDetails details, bool isVertical) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    double newPosition;

    if (isVertical) {
      final localPosition = box.globalToLocal(details.globalPosition);
      newPosition = (localPosition.dx / size.width).clamp(0.2, 0.8);
    } else {
      final localPosition = box.globalToLocal(details.globalPosition);
      newPosition = (localPosition.dy / size.height).clamp(0.2, 0.8);
    }

    widget.onStateChanged(
      widget.state.copyWith(splitPosition: newPosition),
    );
  }

  Widget _buildEditorPane(
    EditorPaneState paneState, {
    required bool isPrimary,
    bool showBorder = true,
  }) {
    final isFocused = paneState.isFocused;
    final document = paneState.document;

    return GestureDetector(
      onTap: () {
        if (isPrimary) {
          widget.onStateChanged(widget.state.focusPrimary());
        } else {
          widget.onStateChanged(widget.state.focusSecondary());
        }
      },
      child: Container(
        decoration: showBorder
            ? BoxDecoration(
                border: Border.all(
                  color: isFocused
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              )
            : null,
        child: Column(
          children: [
            // Pane header (only show in split mode)
            if (widget.state.isSplitEnabled)
              _buildPaneHeader(paneState, isPrimary),
            // Editor content
            Expanded(
              child: document != null
                  ? (document.isResearchItem
                      ? _buildResearchViewer(document)
                      : RichTextEditor(
                          key: ValueKey('${document.id}_$isPrimary'),
                          item: document,
                          content: widget.textContents[document.id] ?? '',
                          useMarkdown: widget.useMarkdown,
                          hasUnsavedChanges: widget.hasUnsavedChanges,
                          pageViewMode: widget.pageViewMode,
                          onPageViewModeChanged: widget.onPageViewModeChanged,
                          onContentChanged: (content) {
                            widget.onContentChanged(document.id, content);
                          },
                        ))
                  : _buildEmptyPane(isPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResearchViewer(BinderItem binderItem) {
    final item = widget.researchItems[binderItem.id];
    if (item == null) {
      return Center(
        child: Text(
          'Unable to load "${binderItem.title}"',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ResearchViewer(
      key: ValueKey('research_${binderItem.id}'),
      item: item,
    );
  }

  Widget _buildPaneHeader(EditorPaneState paneState, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: paneState.isFocused
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPrimary ? Icons.looks_one : Icons.looks_two,
            size: 16,
            color: paneState.isFocused
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              paneState.document?.title ?? 'No document',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    paneState.isFocused ? FontWeight.bold : FontWeight.normal,
                color: paneState.document != null ? null : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (paneState.document != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (isPrimary) {
                  widget.onStateChanged(
                    widget.state.copyWith(
                      primaryPane: paneState.copyWith(document: null),
                    ),
                  );
                } else {
                  widget.onStateChanged(
                    widget.state.copyWith(
                      secondaryPane: paneState.copyWith(document: null),
                    ),
                  );
                }
              },
              tooltip: 'Close document',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPane(bool isPrimary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a document from the binder',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPrimary ? 'Primary pane' : 'Secondary pane',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

/// Toolbar widget for split editor controls
class SplitEditorToolbar extends StatelessWidget {
  final SplitEditorState state;
  final Function(SplitEditorState) onStateChanged;

  const SplitEditorToolbar({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle split
        Tooltip(
          message: state.isSplitEnabled ? 'Close split' : 'Split editor',
          child: IconButton(
            icon: Icon(
              state.isSplitEnabled
                  ? Icons.close_fullscreen
                  : Icons.vertical_split,
              size: 20,
            ),
            onPressed: () {
              onStateChanged(state.toggleSplit());
            },
          ),
        ),
        // Toggle orientation (only show when split is enabled)
        if (state.isSplitEnabled)
          Tooltip(
            message: state.orientation == SplitOrientation.vertical
                ? 'Split horizontally'
                : 'Split vertically',
            child: IconButton(
              icon: Icon(
                state.orientation == SplitOrientation.vertical
                    ? Icons.horizontal_split
                    : Icons.vertical_split,
                size: 20,
              ),
              onPressed: () {
                onStateChanged(state.toggleOrientation());
              },
            ),
          ),
      ],
    );
  }
}
