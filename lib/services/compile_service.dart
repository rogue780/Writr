import '../models/scrivener_project.dart';
import '../models/compile_settings.dart';

/// Service for compiling manuscripts into various output formats.
class CompileService {
  /// Compiles a project using the given settings.
  CompileResult compile(ScrivenerProject project, CompileSettings settings) {
    try {
      // Gather documents to compile
      final documents = _gatherDocuments(project, settings);

      if (documents.isEmpty) {
        return CompileResult.failure('No documents to compile');
      }

      // Compile based on format
      String content;
      switch (settings.format) {
        case CompileFormat.plainText:
          content = _compileToPlainText(documents, settings);
          break;
        case CompileFormat.markdown:
          content = _compileToMarkdown(documents, settings);
          break;
        case CompileFormat.html:
          content = _compileToHtml(documents, settings);
          break;
        case CompileFormat.rtf:
          content = _compileToRtf(documents, settings);
          break;
      }

      // Calculate statistics
      final statistics = _calculateStatistics(documents, settings);

      return CompileResult.success(
        content: content,
        statistics: statistics,
      );
    } catch (e) {
      return CompileResult.failure('Compilation failed: $e');
    }
  }

  /// Gathers documents from the project based on settings.
  List<CompileDocument> _gatherDocuments(
    ScrivenerProject project,
    CompileSettings settings,
  ) {
    final documents = <CompileDocument>[];

    // Find the Manuscript folder (or use all items if not found)
    BinderItem? manuscriptFolder;
    for (final item in project.binderItems) {
      if (item.title.toLowerCase() == 'manuscript' ||
          item.title.toLowerCase() == 'draft') {
        manuscriptFolder = item;
        break;
      }
    }

    final itemsToProcess =
        manuscriptFolder?.children ?? project.binderItems;

    // Recursively gather documents
    _collectDocuments(
      itemsToProcess,
      project,
      settings,
      documents,
      depth: 0,
    );

    return documents;
  }

  void _collectDocuments(
    List<BinderItem> items,
    ScrivenerProject project,
    CompileSettings settings,
    List<CompileDocument> documents, {
    required int depth,
  }) {
    for (final item in items) {
      // Check if this document should be included
      if (settings.includedDocumentIds != null &&
          !settings.includedDocumentIds!.contains(item.id)) {
        continue;
      }

      // Check metadata for includeInCompile setting
      final metadata = project.documentMetadata[item.id];
      if (metadata != null && !metadata.includeInCompile) {
        continue;
      }

      // Get content
      final content = project.textContents[item.id] ?? '';

      // Skip empty documents if configured
      if (!settings.includeEmptyDocuments &&
          content.trim().isEmpty &&
          !item.isFolder) {
        continue;
      }

      // Determine section type
      final sectionType = settings.sectionTypes[item.id] ??
          _inferSectionType(item, depth);

      documents.add(CompileDocument(
        id: item.id,
        title: item.title,
        content: content,
        sectionType: sectionType,
        depth: depth,
        isFolder: item.isFolder,
      ));

      // Process children
      if (item.children.isNotEmpty) {
        _collectDocuments(
          item.children,
          project,
          settings,
          documents,
          depth: depth + 1,
        );
      }
    }
  }

  /// Infers the section type based on the document's position.
  SectionType _inferSectionType(BinderItem item, int depth) {
    if (item.isFolder) {
      return depth == 0 ? SectionType.chapter : SectionType.section;
    }
    return depth == 0 ? SectionType.chapter : SectionType.scene;
  }

  /// Compiles documents to plain text format.
  String _compileToPlainText(
    List<CompileDocument> documents,
    CompileSettings settings,
  ) {
    final buffer = StringBuffer();
    int chapterNumber = 0;

    // Add title page if configured
    if (settings.includeFrontMatter && settings.title != null) {
      buffer.writeln(settings.title!.toUpperCase());
      buffer.writeln();
      if (settings.author != null) {
        buffer.writeln('by ${settings.author}');
      }
      buffer.writeln();
      buffer.writeln('=' * 40);
      buffer.writeln();
      buffer.writeln();
    }

    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];
      final isLastDocument = i == documents.length - 1;

      // Handle chapters
      if (doc.sectionType == SectionType.chapter) {
        chapterNumber++;

        if (settings.addChapterNumbers) {
          buffer.writeln('${settings.chapterPrefix}$chapterNumber');
          buffer.writeln();
        }

        if (!doc.isFolder || doc.content.isNotEmpty) {
          buffer.writeln(doc.title.toUpperCase());
          buffer.writeln();
        }
      }
      // Handle scenes
      else if (doc.sectionType == SectionType.scene) {
        // Add scene separator if not the first scene after a chapter
        if (i > 0 && documents[i - 1].sectionType != SectionType.chapter) {
          buffer.writeln();
          buffer.writeln(settings.sceneSeparator);
          buffer.writeln();
        }
      }

      // Add content
      if (doc.content.isNotEmpty) {
        buffer.writeln(doc.content.trim());
        if (!isLastDocument) {
          buffer.writeln();
        }
      }

      // Add spacing between chapters
      if (doc.sectionType == SectionType.chapter && !isLastDocument) {
        buffer.writeln();
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Compiles documents to Markdown format.
  String _compileToMarkdown(
    List<CompileDocument> documents,
    CompileSettings settings,
  ) {
    final buffer = StringBuffer();
    int chapterNumber = 0;

    // Add title page if configured
    if (settings.includeFrontMatter && settings.title != null) {
      buffer.writeln('# ${settings.title}');
      buffer.writeln();
      if (settings.author != null) {
        buffer.writeln('*by ${settings.author}*');
      }
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];

      // Handle chapters
      if (doc.sectionType == SectionType.chapter) {
        chapterNumber++;

        buffer.writeln();

        if (settings.addChapterNumbers) {
          buffer.writeln('## ${settings.chapterPrefix}$chapterNumber: ${doc.title}');
        } else {
          buffer.writeln('## ${doc.title}');
        }
        buffer.writeln();
      }
      // Handle scenes
      else if (doc.sectionType == SectionType.scene) {
        // Add scene separator
        if (i > 0 && documents[i - 1].sectionType != SectionType.chapter) {
          buffer.writeln();
          buffer.writeln(settings.sceneSeparator);
          buffer.writeln();
        }
      }
      // Handle sections
      else if (doc.sectionType == SectionType.section) {
        buffer.writeln();
        buffer.writeln('### ${doc.title}');
        buffer.writeln();
      }

      // Add content
      if (doc.content.isNotEmpty) {
        // Convert paragraphs to Markdown (double newlines)
        final paragraphs = doc.content.trim().split(RegExp(r'\n\s*\n'));
        for (final paragraph in paragraphs) {
          buffer.writeln(paragraph.trim());
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }

  /// Compiles documents to HTML format.
  String _compileToHtml(
    List<CompileDocument> documents,
    CompileSettings settings,
  ) {
    final buffer = StringBuffer();
    int chapterNumber = 0;

    // HTML header
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    if (settings.title != null) {
      buffer.writeln('  <title>${_escapeHtml(settings.title!)}</title>');
    }
    if (settings.author != null) {
      buffer.writeln('  <meta name="author" content="${_escapeHtml(settings.author!)}">');
    }
    buffer.writeln('  <style>');
    buffer.writeln('    body {');
    buffer.writeln('      font-family: ${settings.fontFamily}, serif;');
    buffer.writeln('      font-size: ${settings.fontSize}pt;');
    buffer.writeln('      line-height: ${settings.lineSpacing};');
    buffer.writeln('      max-width: 800px;');
    buffer.writeln('      margin: 0 auto;');
    buffer.writeln('      padding: 2em;');
    buffer.writeln('    }');
    buffer.writeln('    h1, h2, h3 { margin-top: 2em; }');
    buffer.writeln('    p { text-indent: ${settings.useFirstLineIndent ? "${settings.paragraphIndent}em" : "0"}; margin: ${settings.useFirstLineIndent ? "0" : "1em 0"}; }');
    buffer.writeln('    .scene-separator { text-align: center; margin: 2em 0; }');
    buffer.writeln('    .title-page { text-align: center; margin-bottom: 4em; }');
    buffer.writeln('    .chapter { page-break-before: ${settings.pageBreakBetweenChapters ? "always" : "auto"}; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // Add title page if configured
    if (settings.includeFrontMatter && settings.title != null) {
      buffer.writeln('  <div class="title-page">');
      buffer.writeln('    <h1>${_escapeHtml(settings.title!)}</h1>');
      if (settings.author != null) {
        buffer.writeln('    <p><em>by ${_escapeHtml(settings.author!)}</em></p>');
      }
      buffer.writeln('  </div>');
      buffer.writeln('  <hr>');
    }

    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];

      // Handle chapters
      if (doc.sectionType == SectionType.chapter) {
        chapterNumber++;

        buffer.writeln('  <div class="chapter">');
        if (settings.addChapterNumbers) {
          buffer.writeln('    <h2>${settings.chapterPrefix}$chapterNumber: ${_escapeHtml(doc.title)}</h2>');
        } else {
          buffer.writeln('    <h2>${_escapeHtml(doc.title)}</h2>');
        }
      }
      // Handle scenes
      else if (doc.sectionType == SectionType.scene) {
        // Add scene separator
        if (i > 0 && documents[i - 1].sectionType != SectionType.chapter) {
          buffer.writeln('    <p class="scene-separator">${_escapeHtml(settings.sceneSeparator)}</p>');
        }
      }
      // Handle sections
      else if (doc.sectionType == SectionType.section) {
        buffer.writeln('    <h3>${_escapeHtml(doc.title)}</h3>');
      }

      // Add content
      if (doc.content.isNotEmpty) {
        final paragraphs = doc.content.trim().split(RegExp(r'\n\s*\n'));
        for (final paragraph in paragraphs) {
          if (paragraph.trim().isNotEmpty) {
            buffer.writeln('    <p>${_escapeHtml(paragraph.trim())}</p>');
          }
        }
      }

      // Close chapter div
      if (doc.sectionType == SectionType.chapter) {
        // Find next chapter or end
        final nextChapterIndex = documents.indexWhere(
          (d) => d.sectionType == SectionType.chapter,
          i + 1,
        );
        if (nextChapterIndex == -1 || nextChapterIndex == i + 1) {
          buffer.writeln('  </div>');
        }
      }
    }

    // Close any remaining chapter divs
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// Compiles documents to RTF format.
  String _compileToRtf(
    List<CompileDocument> documents,
    CompileSettings settings,
  ) {
    final buffer = StringBuffer();
    int chapterNumber = 0;

    // RTF header
    buffer.write(r'{\rtf1\ansi\deff0');
    buffer.write(r'{\fonttbl{\f0 ' + settings.fontFamily + r';}}');
    buffer.write(r'\f0\fs' + (settings.fontSize * 2).toInt().toString());
    buffer.writeln();

    // Title page
    if (settings.includeFrontMatter && settings.title != null) {
      buffer.write(r'\qc\b\fs48 ');
      buffer.write(_escapeRtf(settings.title!));
      buffer.writeln(r'\b0\par\par');
      if (settings.author != null) {
        buffer.write(r'\fs24 by ');
        buffer.write(_escapeRtf(settings.author!));
        buffer.writeln(r'\par');
      }
      buffer.writeln(r'\ql\par\par');
    }

    for (int i = 0; i < documents.length; i++) {
      final doc = documents[i];

      // Handle chapters
      if (doc.sectionType == SectionType.chapter) {
        chapterNumber++;

        if (settings.pageBreakBetweenChapters && i > 0) {
          buffer.write(r'\page');
        }

        buffer.write(r'\par\b\fs32 ');
        if (settings.addChapterNumbers) {
          buffer.write('${settings.chapterPrefix}$chapterNumber: ');
        }
        buffer.write(_escapeRtf(doc.title));
        buffer.writeln(r'\b0\fs' + (settings.fontSize * 2).toInt().toString() + r'\par\par');
      }
      // Handle scenes
      else if (doc.sectionType == SectionType.scene) {
        if (i > 0 && documents[i - 1].sectionType != SectionType.chapter) {
          buffer.write(r'\qc ');
          buffer.write(_escapeRtf(settings.sceneSeparator));
          buffer.writeln(r'\ql\par\par');
        }
      }

      // Add content
      if (doc.content.isNotEmpty) {
        final paragraphs = doc.content.trim().split(RegExp(r'\n\s*\n'));
        for (final paragraph in paragraphs) {
          if (paragraph.trim().isNotEmpty) {
            if (settings.useFirstLineIndent) {
              buffer.write('\\fi${(settings.paragraphIndent * 720).toInt()} ');
            }
            buffer.write(_escapeRtf(paragraph.trim()));
            buffer.writeln(r'\par');
            if (!settings.useFirstLineIndent) {
              buffer.writeln(r'\par');
            }
          }
        }
      }
    }

    buffer.write('}');
    return buffer.toString();
  }

  /// Escapes text for HTML output.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Escapes text for RTF output.
  String _escapeRtf(String text) {
    final buffer = StringBuffer();
    for (final char in text.runes) {
      if (char == 0x5C) {
        // backslash
        buffer.write(r'\\');
      } else if (char == 0x7B) {
        // {
        buffer.write(r'\{');
      } else if (char == 0x7D) {
        // }
        buffer.write(r'\}');
      } else if (char > 127) {
        // Unicode character
        buffer.write(r'\u');
        buffer.write(char.toString());
        buffer.write('?');
      } else {
        buffer.writeCharCode(char);
      }
    }
    return buffer.toString();
  }

  /// Calculates statistics for the compiled documents.
  CompileStatistics _calculateStatistics(
    List<CompileDocument> documents,
    CompileSettings settings,
  ) {
    int wordCount = 0;
    int characterCount = 0;
    int chapterCount = 0;
    int sceneCount = 0;

    for (final doc in documents) {
      // Count words
      if (doc.content.isNotEmpty) {
        wordCount += doc.content
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        characterCount += doc.content.length;
      }

      // Count sections
      if (doc.sectionType == SectionType.chapter) {
        chapterCount++;
      } else if (doc.sectionType == SectionType.scene) {
        sceneCount++;
      }
    }

    return CompileStatistics(
      documentCount: documents.length,
      wordCount: wordCount,
      characterCount: characterCount,
      chapterCount: chapterCount,
      sceneCount: sceneCount,
    );
  }

  /// Gets a preview of the compiled output (first N characters).
  String getPreview(ScrivenerProject project, CompileSettings settings, {int maxLength = 2000}) {
    final result = compile(project, settings);
    if (!result.success || result.content == null) {
      return result.error ?? 'Preview not available';
    }

    final content = result.content!;
    if (content.length <= maxLength) {
      return content;
    }

    return '${content.substring(0, maxLength)}...\n\n[Preview truncated]';
  }
}
