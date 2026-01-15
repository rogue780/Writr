import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/research_item.dart';

/// A widget for viewing images with zoom and pan support
class ImageViewer extends StatefulWidget {
  final ResearchItem item;
  final VoidCallback? onDownload;

  const ImageViewer({
    super.key,
    required this.item,
    this.onDownload,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;
  bool _showControls = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.25).clamp(0.5, 5.0);
    _setScale(newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.25).clamp(0.5, 5.0);
    _setScale(newScale);
  }

  void _setScale(double scale) {
    final matrix = Matrix4.identity()..setEntry(0, 0, scale)..setEntry(1, 1, scale)..setEntry(2, 2, scale);
    _transformationController.value = matrix;
    setState(() {
      _currentScale = scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        if (_showControls) _buildToolbar(context),
        if (_showControls) const Divider(height: 1),
        // Image content
        Expanded(
          child: _buildImageContent(context),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.image, color: Colors.blue),
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
                  '${widget.item.formattedFileSize} • ${widget.item.mimeType ?? "Image"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _currentScale > 0.5 ? _zoomOut : null,
            tooltip: 'Zoom Out',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${(_currentScale * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _currentScale < 5.0 ? _zoomIn : null,
            tooltip: 'Zoom In',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
          const VerticalDivider(width: 16),
          if (widget.onDownload != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: widget.onDownload,
              tooltip: 'Download',
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (widget.item.data == null || widget.item.data!.isEmpty) {
      return _buildNoImagePlaceholder(context);
    }

    return GestureDetector(
      onDoubleTap: _resetZoom,
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.grey[900],
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          onInteractionEnd: (details) {
            // Update current scale from transformation matrix
            final scale = _transformationController.value.getMaxScaleOnAxis();
            setState(() {
              _currentScale = scale;
            });
          },
          child: Center(
            child: Image.memory(
              widget.item.data!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder(context, error.toString());
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Image not available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context, String error) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red[600],
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thumbnail widget for displaying image previews in lists
class ImageThumbnail extends StatelessWidget {
  final Uint8List? data;
  final double size;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ImageThumbnail({
    super.key,
    this.data,
    this.size = 48,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: data != null && data!.isNotEmpty
            ? Image.memory(
                data!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.broken_image,
                    size: size * 0.5,
                    color: Colors.grey[500],
                  );
                },
              )
            : Icon(
                Icons.image,
                size: size * 0.5,
                color: Colors.grey[500],
              ),
      ),
    );
  }
}
