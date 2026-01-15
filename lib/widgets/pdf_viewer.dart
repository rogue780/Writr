import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/research_item.dart';

/// A widget for viewing PDF documents
///
/// Note: Full PDF rendering requires platform-specific implementations.
/// This widget provides a preview/placeholder with download option.
/// For full PDF viewing, consider adding 'syncfusion_flutter_pdfviewer'
/// or 'pdfx' package.
class PdfViewer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        _buildToolbar(context),
        const Divider(height: 1),
        // Content area
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
          const Icon(Icons.picture_as_pdf, color: Colors.red),
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
                  '${item.formattedFileSize} • PDF Document',
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
          if (onOpenExternal != null && !kIsWeb)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: onOpenExternal,
              tooltip: 'Open in external viewer',
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // If we have data, show a preview indicator
    if (item.data != null && item.data!.isNotEmpty) {
      return _buildPdfPreview(context, item.data!);
    }

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
            item.title,
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
          if (onDownload != null)
            ElevatedButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download PDF'),
            ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview(BuildContext context, Uint8List data) {
    // Check if data looks like a valid PDF (starts with %PDF)
    final isPdf = data.length > 4 &&
        data[0] == 0x25 && // %
        data[1] == 0x50 && // P
        data[2] == 0x44 && // D
        data[3] == 0x46; // F

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
                    color: isPdf ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.formattedFileSize,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (isPdf)
                    const Text(
                      'PDF document loaded successfully.\n'
                      'Download to view in your system PDF viewer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    const Text(
                      'This file may be corrupted or not a valid PDF.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onDownload != null)
                        ElevatedButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                      if (onDownload != null && onOpenExternal != null && !kIsWeb)
                        const SizedBox(width: 16),
                      if (onOpenExternal != null && !kIsWeb)
                        OutlinedButton.icon(
                          onPressed: onOpenExternal,
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

/// Placeholder for future PDF annotation support
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
