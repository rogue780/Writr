import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/research_item.dart';
import '../utils/web_download.dart';
import 'pdf_viewer.dart';
import 'image_viewer.dart';

/// A widget that displays the appropriate viewer for a research item
class ResearchViewer extends StatelessWidget {
  final ResearchItem item;
  final VoidCallback? onDelete;
  final Function(ResearchItem)? onUpdate;

  const ResearchViewer({
    super.key,
    required this.item,
    this.onDelete,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case ResearchItemType.pdf:
        return PdfViewer(
          item: item,
          onDownload: () => _downloadItem(context),
        );
      case ResearchItemType.image:
        return ImageViewer(
          item: item,
          onDownload: () => _downloadItem(context),
        );
      case ResearchItemType.text:
      case ResearchItemType.markdown:
        return _TextViewer(
          item: item,
          onDownload: () => _downloadItem(context),
        );
      case ResearchItemType.webArchive:
        return _WebArchiveViewer(
          item: item,
          onDownload: () => _downloadItem(context),
        );
    }
  }

  void _downloadItem(BuildContext context) {
    if (item.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data available to download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fileName = '${item.title}.${item.fileExtension}';

    if (kIsWeb) {
      downloadBytes(item.data!.toList(), fileName);
    } else {
      // For desktop, show a message - could integrate file_picker save dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File ready: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// Viewer for text files
class _TextViewer extends StatelessWidget {
  final ResearchItem item;
  final VoidCallback? onDownload;

  const _TextViewer({
    required this.item,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        const Divider(height: 1),
        Expanded(
          child: _buildContent(context),
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
          Icon(
            item.type == ResearchItemType.markdown
                ? Icons.code
                : Icons.text_snippet,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.formattedFileSize} • ${item.type.displayName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onDownload != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: onDownload,
              tooltip: 'Download',
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (item.data == null || item.data!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_snippet,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No content available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    // Decode text content
    String content;
    try {
      content = String.fromCharCodes(item.data!);
    } catch (e) {
      content = 'Unable to decode text content';
    }

    return Container(
      color: Colors.grey[100],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              fontFamily: item.type == ResearchItemType.markdown
                  ? 'monospace'
                  : null,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Viewer for web archive files (placeholder)
class _WebArchiveViewer extends StatelessWidget {
  final ResearchItem item;
  final VoidCallback? onDownload;

  const _WebArchiveViewer({
    required this.item,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        const Divider(height: 1),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.web,
                  size: 80,
                  color: Colors.orange.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Web archive preview not available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.formattedFileSize,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                if (onDownload != null)
                  ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ),
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
          const Icon(Icons.web, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.formattedFileSize} • Web Archive',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (onDownload != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: onDownload,
              tooltip: 'Download',
            ),
        ],
      ),
    );
  }
}

/// Card widget for displaying research item in a list/grid
class ResearchItemCard extends StatelessWidget {
  final ResearchItem item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ResearchItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail/Preview area
            Expanded(
              child: _buildThumbnail(context),
            ),
            // Info area
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForType(item.type),
                        size: 16,
                        color: _getColorForType(item.type),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onDelete != null)
                        InkWell(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.type.displayName} • ${item.formattedFileSize}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (item.type == ResearchItemType.image && item.data != null) {
      return Image.memory(
        item.data!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderThumbnail(context);
        },
      );
    }

    return _buildPlaceholderThumbnail(context);
  }

  Widget _buildPlaceholderThumbnail(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          _getIconForType(item.type),
          size: 48,
          color: _getColorForType(item.type).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  IconData _getIconForType(ResearchItemType type) {
    switch (type) {
      case ResearchItemType.pdf:
        return Icons.picture_as_pdf;
      case ResearchItemType.image:
        return Icons.image;
      case ResearchItemType.webArchive:
        return Icons.web;
      case ResearchItemType.text:
        return Icons.text_snippet;
      case ResearchItemType.markdown:
        return Icons.code;
    }
  }

  Color _getColorForType(ResearchItemType type) {
    switch (type) {
      case ResearchItemType.pdf:
        return Colors.red;
      case ResearchItemType.image:
        return Colors.green;
      case ResearchItemType.webArchive:
        return Colors.orange;
      case ResearchItemType.text:
      case ResearchItemType.markdown:
        return Colors.grey;
    }
  }
}
