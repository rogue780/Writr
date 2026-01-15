import 'dart:typed_data';

/// Represents a research item (PDF, image, web archive, etc.) in the project
class ResearchItem {
  final String id;
  final String title;
  final ResearchItemType type;
  final String? filePath; // Path within project for file-based storage
  final Uint8List? data; // Raw bytes for web-based storage
  final String? mimeType;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? description;
  final List<String> linkedDocumentIds; // Documents this research is linked to

  ResearchItem({
    required this.id,
    required this.title,
    required this.type,
    this.filePath,
    this.data,
    this.mimeType,
    this.fileSize,
    required this.createdAt,
    required this.modifiedAt,
    this.description,
    this.linkedDocumentIds = const [],
  });

  /// Create a research item from imported file
  factory ResearchItem.fromImport({
    required String title,
    required ResearchItemType type,
    required Uint8List data,
    String? mimeType,
    String? description,
  }) {
    final now = DateTime.now();
    return ResearchItem(
      id: '${now.millisecondsSinceEpoch}_${title.hashCode.abs()}',
      title: title,
      type: type,
      data: data,
      mimeType: mimeType,
      fileSize: data.length,
      createdAt: now,
      modifiedAt: now,
      description: description,
    );
  }

  /// Copy with updated fields
  ResearchItem copyWith({
    String? title,
    String? description,
    List<String>? linkedDocumentIds,
    DateTime? modifiedAt,
  }) {
    return ResearchItem(
      id: id,
      title: title ?? this.title,
      type: type,
      filePath: filePath,
      data: data,
      mimeType: mimeType,
      fileSize: fileSize,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? DateTime.now(),
      description: description ?? this.description,
      linkedDocumentIds: linkedDocumentIds ?? this.linkedDocumentIds,
    );
  }

  /// Add a linked document
  ResearchItem withLinkedDocument(String documentId) {
    if (linkedDocumentIds.contains(documentId)) return this;
    return copyWith(
      linkedDocumentIds: [...linkedDocumentIds, documentId],
    );
  }

  /// Remove a linked document
  ResearchItem withUnlinkedDocument(String documentId) {
    return copyWith(
      linkedDocumentIds: linkedDocumentIds.where((id) => id != documentId).toList(),
    );
  }

  /// Get file extension based on type and mime type
  String get fileExtension {
    switch (type) {
      case ResearchItemType.pdf:
        return 'pdf';
      case ResearchItemType.image:
        if (mimeType != null) {
          if (mimeType!.contains('png')) return 'png';
          if (mimeType!.contains('gif')) return 'gif';
          if (mimeType!.contains('webp')) return 'webp';
        }
        return 'jpg';
      case ResearchItemType.webArchive:
        return 'webarchive';
      case ResearchItemType.text:
        return 'txt';
      case ResearchItemType.markdown:
        return 'md';
    }
  }

  /// Get formatted file size string
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown size';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'filePath': filePath,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'description': description,
      'linkedDocumentIds': linkedDocumentIds,
      // Note: data is stored separately, not in JSON
    };
  }

  /// Create from JSON
  factory ResearchItem.fromJson(Map<String, dynamic> json, {Uint8List? data}) {
    return ResearchItem(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ResearchItemType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ResearchItemType.text,
      ),
      filePath: json['filePath'] as String?,
      data: data,
      mimeType: json['mimeType'] as String?,
      fileSize: json['fileSize'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      description: json['description'] as String?,
      linkedDocumentIds: (json['linkedDocumentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Types of research items
enum ResearchItemType {
  pdf('PDF Document', 'application/pdf'),
  image('Image', 'image/*'),
  webArchive('Web Archive', 'application/x-webarchive'),
  text('Text File', 'text/plain'),
  markdown('Markdown', 'text/markdown');

  final String displayName;
  final String mimeTypePattern;

  const ResearchItemType(this.displayName, this.mimeTypePattern);

  /// Determine type from mime type string
  static ResearchItemType fromMimeType(String mimeType) {
    final lower = mimeType.toLowerCase();
    if (lower.contains('pdf')) return ResearchItemType.pdf;
    if (lower.startsWith('image/')) return ResearchItemType.image;
    if (lower.contains('webarchive')) return ResearchItemType.webArchive;
    if (lower.contains('markdown')) return ResearchItemType.markdown;
    return ResearchItemType.text;
  }

  /// Determine type from file extension
  static ResearchItemType fromExtension(String extension) {
    final lower = extension.toLowerCase().replaceAll('.', '');
    switch (lower) {
      case 'pdf':
        return ResearchItemType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return ResearchItemType.image;
      case 'webarchive':
        return ResearchItemType.webArchive;
      case 'md':
      case 'markdown':
        return ResearchItemType.markdown;
      default:
        return ResearchItemType.text;
    }
  }
}
