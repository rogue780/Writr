import 'package:flutter/material.dart';
import '../models/scrivener_project.dart';
import '../models/document_metadata.dart';
import 'index_card.dart';

/// Corkboard view displaying documents as index cards in a grid layout.
class CorkboardView extends StatefulWidget {
  final BinderItem folder;
  final Map<String, DocumentMetadata> metadata;
  final BinderItem? selectedItem;
  final Function(BinderItem) onItemSelected;
  final Function(BinderItem) onItemDoubleClicked;
  final Function(String, DocumentMetadata) onMetadataChanged;

  const CorkboardView({
    super.key,
    required this.folder,
    required this.metadata,
    this.selectedItem,
    required this.onItemSelected,
    required this.onItemDoubleClicked,
    required this.onMetadataChanged,
  });

  @override
  State<CorkboardView> createState() => _CorkboardViewState();
}

class _CorkboardViewState extends State<CorkboardView> {
  double _cardScale = 1.0;
  final List<double> _scaleOptions = [0.75, 1.0, 1.25, 1.5];

  @override
  Widget build(BuildContext context) {
    final children = widget.folder.children;

    return Column(
      children: [
        // Toolbar
        _buildToolbar(context),
        // Corkboard
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.brown[200],
              // Cork-like pattern using gradient
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown[100]!,
                  Colors.brown[200]!,
                  Colors.brown[100]!,
                  Colors.brown[200]!,
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
            child: children.isEmpty
                ? _buildEmptyState(context)
                : _buildCardGrid(context, children),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
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
          Icon(Icons.folder, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            widget.folder.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            '(${widget.folder.children.length} items)',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Spacer(),
          // Zoom controls
          const Text('Card Size: ', style: TextStyle(fontSize: 13)),
          DropdownButton<double>(
            value: _cardScale,
            underline: const SizedBox(),
            isDense: true,
            items: _scaleOptions.map((scale) {
              return DropdownMenuItem(
                value: scale,
                child: Text('${(scale * 100).toInt()}%'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _cardScale = value;
                });
              }
            },
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
          Icon(
            Icons.dashboard_outlined,
            size: 64,
            color: Colors.brown[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No documents in this folder',
            style: TextStyle(
              fontSize: 16,
              color: Colors.brown[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add documents to see them as index cards',
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(BuildContext context, List<BinderItem> children) {
    final cardWidth = (180 * _cardScale).toInt();
    final cardHeight = (140 * _cardScale).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / (cardWidth + 20)).floor();
        final effectiveCrossAxisCount = crossAxisCount > 0 ? crossAxisCount : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveCrossAxisCount,
            childAspectRatio: cardWidth / cardHeight,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) {
            final item = children[index];
            final itemMetadata = widget.metadata[item.id];

            return Draggable<BinderItem>(
              data: item,
              feedback: Material(
                elevation: 8,
                child: Transform.scale(
                  scale: _cardScale,
                  child: IndexCard(
                    item: item,
                    metadata: itemMetadata,
                    isSelected: false,
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.5,
                child: Transform.scale(
                  scale: _cardScale,
                  child: IndexCard(
                    item: item,
                    metadata: itemMetadata,
                    isSelected: false,
                  ),
                ),
              ),
              child: Transform.scale(
                scale: _cardScale,
                child: IndexCard(
                  item: item,
                  metadata: itemMetadata,
                  isSelected: widget.selectedItem?.id == item.id,
                  onTap: () => widget.onItemSelected(item),
                  onDoubleTap: () => widget.onItemDoubleClicked(item),
                  onSynopsisChanged: (synopsis) {
                    // Update the metadata with the new synopsis
                    final existingMetadata = itemMetadata ??
                        DocumentMetadata.empty(item.id);
                    widget.onMetadataChanged(
                      item.id,
                      existingMetadata.copyWith(
                        synopsis: synopsis,
                        modifiedAt: DateTime.now(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
