import 'package:flutter/material.dart';
import 'scrivener_project.dart';

/// Output format for compilation.
enum CompileFormat {
  plainText('Plain Text', 'txt', Icons.text_snippet),
  markdown('Markdown', 'md', Icons.code),
  html('HTML', 'html', Icons.html),
  rtf('Rich Text', 'rtf', Icons.text_fields);

  final String displayName;
  final String extension;
  final IconData icon;

  const CompileFormat(this.displayName, this.extension, this.icon);
}

/// Section type for compile formatting.
enum SectionType {
  chapter('Chapter', 'A major division of the manuscript'),
  scene('Scene', 'A scene within a chapter'),
  section('Section', 'A generic section'),
  frontMatter('Front Matter', 'Title page, copyright, etc.'),
  backMatter('Back Matter', 'Appendix, notes, etc.');

  final String displayName;
  final String description;

  const SectionType(this.displayName, this.description);
}

/// Settings for a compile operation.
class CompileSettings {
  /// Output format
  final CompileFormat format;

  /// Output file name (without extension)
  final String outputName;

  /// Whether to include front matter
  final bool includeFrontMatter;

  /// Whether to include back matter
  final bool includeBackMatter;

  /// Title for the compiled document
  final String? title;

  /// Author name
  final String? author;

  /// Whether to add chapter numbers
  final bool addChapterNumbers;

  /// Chapter number prefix (e.g., "Chapter ")
  final String chapterPrefix;

  /// Scene separator (e.g., "* * *" or "###")
  final String sceneSeparator;

  /// Whether to include empty documents
  final bool includeEmptyDocuments;

  /// Whether to add page breaks between chapters (for formats that support it)
  final bool pageBreakBetweenChapters;

  /// Documents to include (by ID). If null, include all.
  final Set<String>? includedDocumentIds;

  /// Section type assignments (document ID -> section type)
  final Map<String, SectionType> sectionTypes;

  /// Font family for output (for formats that support it)
  final String fontFamily;

  /// Font size for output (for formats that support it)
  final double fontSize;

  /// Line spacing multiplier
  final double lineSpacing;

  /// Paragraph indent (in ems)
  final double paragraphIndent;

  /// Whether to use first-line indent vs paragraph spacing
  final bool useFirstLineIndent;

  const CompileSettings({
    this.format = CompileFormat.plainText,
    this.outputName = 'Manuscript',
    this.includeFrontMatter = true,
    this.includeBackMatter = true,
    this.title,
    this.author,
    this.addChapterNumbers = true,
    this.chapterPrefix = 'Chapter ',
    this.sceneSeparator = '* * *',
    this.includeEmptyDocuments = false,
    this.pageBreakBetweenChapters = true,
    this.includedDocumentIds,
    this.sectionTypes = const {},
    this.fontFamily = 'Times New Roman',
    this.fontSize = 12.0,
    this.lineSpacing = 2.0,
    this.paragraphIndent = 0.5,
    this.useFirstLineIndent = true,
  });

  /// Creates a copy with updated fields.
  CompileSettings copyWith({
    CompileFormat? format,
    String? outputName,
    bool? includeFrontMatter,
    bool? includeBackMatter,
    String? title,
    String? author,
    bool? addChapterNumbers,
    String? chapterPrefix,
    String? sceneSeparator,
    bool? includeEmptyDocuments,
    bool? pageBreakBetweenChapters,
    Set<String>? includedDocumentIds,
    Map<String, SectionType>? sectionTypes,
    String? fontFamily,
    double? fontSize,
    double? lineSpacing,
    double? paragraphIndent,
    bool? useFirstLineIndent,
  }) {
    return CompileSettings(
      format: format ?? this.format,
      outputName: outputName ?? this.outputName,
      includeFrontMatter: includeFrontMatter ?? this.includeFrontMatter,
      includeBackMatter: includeBackMatter ?? this.includeBackMatter,
      title: title ?? this.title,
      author: author ?? this.author,
      addChapterNumbers: addChapterNumbers ?? this.addChapterNumbers,
      chapterPrefix: chapterPrefix ?? this.chapterPrefix,
      sceneSeparator: sceneSeparator ?? this.sceneSeparator,
      includeEmptyDocuments: includeEmptyDocuments ?? this.includeEmptyDocuments,
      pageBreakBetweenChapters: pageBreakBetweenChapters ?? this.pageBreakBetweenChapters,
      includedDocumentIds: includedDocumentIds ?? this.includedDocumentIds,
      sectionTypes: sectionTypes ?? this.sectionTypes,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      paragraphIndent: paragraphIndent ?? this.paragraphIndent,
      useFirstLineIndent: useFirstLineIndent ?? this.useFirstLineIndent,
    );
  }

  /// Creates default settings from a project.
  factory CompileSettings.fromProject(ScrivenerProject project) {
    return CompileSettings(
      outputName: project.name,
      title: project.name,
    );
  }
}

/// Result of a compile operation.
class CompileResult {
  /// Whether the compile was successful
  final bool success;

  /// The compiled content as a string
  final String? content;

  /// The compiled content as bytes (for binary formats)
  final List<int>? bytes;

  /// Error message if compilation failed
  final String? error;

  /// Statistics about the compiled document
  final CompileStatistics? statistics;

  const CompileResult({
    required this.success,
    this.content,
    this.bytes,
    this.error,
    this.statistics,
  });

  factory CompileResult.success({
    String? content,
    List<int>? bytes,
    CompileStatistics? statistics,
  }) {
    return CompileResult(
      success: true,
      content: content,
      bytes: bytes,
      statistics: statistics,
    );
  }

  factory CompileResult.failure(String error) {
    return CompileResult(
      success: false,
      error: error,
    );
  }
}

/// Statistics about a compiled document.
class CompileStatistics {
  final int documentCount;
  final int wordCount;
  final int characterCount;
  final int chapterCount;
  final int sceneCount;

  const CompileStatistics({
    required this.documentCount,
    required this.wordCount,
    required this.characterCount,
    required this.chapterCount,
    required this.sceneCount,
  });
}

/// A document to be compiled with its metadata.
class CompileDocument {
  final String id;
  final String title;
  final String content;
  final SectionType sectionType;
  final int depth;
  final bool isFolder;

  const CompileDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.sectionType,
    required this.depth,
    required this.isFolder,
  });
}
