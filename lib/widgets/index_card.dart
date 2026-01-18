import 'package:flutter/material.dart';
import '../models/scrivener_project.dart';
import '../models/document_metadata.dart';

/// An index card widget representing a single document in the corkboard view.
class IndexCard extends StatefulWidget {
  final BinderItem item;
  final DocumentMetadata? metadata;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(String)? onSynopsisChanged;

  const IndexCard({
    super.key,
    required this.item,
    this.metadata,
    this.isSelected = false,
    this.onTap,
    this.onDoubleTap,
    this.onSynopsisChanged,
  });

  @override
  State<IndexCard> createState() => _IndexCardState();
}

class _IndexCardState extends State<IndexCard> {
  bool _isEditingSynopsis = false;
  late TextEditingController _synopsisController;
  late FocusNode _synopsisFocusNode;

  @override
  void initState() {
    super.initState();
    _synopsisController = TextEditingController(
      text: widget.metadata?.synopsis ?? '',
    );
    _synopsisFocusNode = FocusNode();
    _synopsisFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(IndexCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metadata?.synopsis != widget.metadata?.synopsis &&
        !_isEditingSynopsis) {
      _synopsisController.text = widget.metadata?.synopsis ?? '';
    }
  }

  @override
  void dispose() {
    _synopsisFocusNode.removeListener(_onFocusChange);
    _synopsisFocusNode.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_synopsisFocusNode.hasFocus && _isEditingSynopsis) {
      _finishEditing();
    }
  }

  void _startEditing() {
    setState(() {
      _isEditingSynopsis = true;
    });
    _synopsisFocusNode.requestFocus();
  }

  void _finishEditing() {
    setState(() {
      _isEditingSynopsis = false;
    });
    widget.onSynopsisChanged?.call(_synopsisController.text);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = widget.metadata?.label != null
        ? Color(widget.metadata!.label!.colorValue)
        : null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isSelected ? Colors.blue : Colors.amber.shade300,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title bar with optional label color - double tap opens editor
            GestureDetector(
              onDoubleTap: widget.onDoubleTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: labelColor ?? Colors.amber[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.item.isFolder ? Icons.folder : Icons.description,
                      size: 14,
                      color: labelColor != null
                          ? _contrastColor(labelColor)
                          : Colors.brown[700],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: labelColor != null
                              ? _contrastColor(labelColor)
                              : Colors.brown[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Synopsis area - click to edit
            Expanded(
              child: GestureDetector(
                onTap: _isEditingSynopsis ? null : _startEditing,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _isEditingSynopsis
                      ? _buildSynopsisEditor()
                      : _buildSynopsisDisplay(),
                ),
              ),
            ),
            // Status indicator at bottom
            if (widget.metadata?.status != null &&
                widget.metadata!.status != DocumentStatus.noStatus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                ),
                child: Text(
                  widget.metadata!.status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.brown[600],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSynopsisDisplay() {
    final hasSynopsis = widget.metadata?.synopsis.isNotEmpty == true;

    return Text(
      hasSynopsis ? widget.metadata!.synopsis : 'Click to add synopsis...',
      style: TextStyle(
        fontSize: 11,
        color: hasSynopsis ? Colors.brown[700] : Colors.brown[400],
        fontStyle: hasSynopsis ? FontStyle.normal : FontStyle.italic,
      ),
      maxLines: 5,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSynopsisEditor() {
    return TextField(
      controller: _synopsisController,
      focusNode: _synopsisFocusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        fontSize: 11,
        color: Colors.brown[700],
      ),
      decoration: InputDecoration(
        hintText: 'Enter synopsis...',
        hintStyle: TextStyle(
          fontSize: 11,
          color: Colors.brown[400],
          fontStyle: FontStyle.italic,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
      onSubmitted: (_) => _finishEditing(),
      onTapOutside: (_) => _finishEditing(),
    );
  }

  Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}
