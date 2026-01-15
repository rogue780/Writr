import 'package:flutter/material.dart';

/// Represents a document template
class DocumentTemplate {
  final String id;
  final String name;
  final String description;
  final String content;
  final DocumentTemplateType type;
  final IconData icon;
  final bool isBuiltIn;
  final DateTime createdAt;
  final Map<String, String> metadata;

  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.type,
    this.icon = Icons.description,
    this.isBuiltIn = false,
    required this.createdAt,
    this.metadata = const {},
  });

  DocumentTemplate copyWith({
    String? name,
    String? description,
    String? content,
    DocumentTemplateType? type,
    IconData? icon,
    Map<String, String>? metadata,
  }) {
    return DocumentTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isBuiltIn: isBuiltIn,
      createdAt: createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'content': content,
      'type': type.name,
      'icon': icon.codePoint,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      content: json['content'] as String,
      type: DocumentTemplateType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocumentTemplateType.general,
      ),
      icon: IconData(
        json['icon'] as int? ?? Icons.description.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: Map<String, String>.from(json['metadata'] as Map? ?? {}),
    );
  }
}

/// Type of document template
enum DocumentTemplateType {
  general,
  chapter,
  scene,
  character,
  location,
  worldBuilding,
  outline,
  notes,
  research,
}

extension DocumentTemplateTypeExtension on DocumentTemplateType {
  String get displayName {
    switch (this) {
      case DocumentTemplateType.general:
        return 'General';
      case DocumentTemplateType.chapter:
        return 'Chapter';
      case DocumentTemplateType.scene:
        return 'Scene';
      case DocumentTemplateType.character:
        return 'Character';
      case DocumentTemplateType.location:
        return 'Location';
      case DocumentTemplateType.worldBuilding:
        return 'World Building';
      case DocumentTemplateType.outline:
        return 'Outline';
      case DocumentTemplateType.notes:
        return 'Notes';
      case DocumentTemplateType.research:
        return 'Research';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentTemplateType.general:
        return Icons.description;
      case DocumentTemplateType.chapter:
        return Icons.menu_book;
      case DocumentTemplateType.scene:
        return Icons.movie;
      case DocumentTemplateType.character:
        return Icons.person;
      case DocumentTemplateType.location:
        return Icons.place;
      case DocumentTemplateType.worldBuilding:
        return Icons.public;
      case DocumentTemplateType.outline:
        return Icons.format_list_numbered;
      case DocumentTemplateType.notes:
        return Icons.note;
      case DocumentTemplateType.research:
        return Icons.science;
    }
  }
}

/// Represents a project template
class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final ProjectTemplateType type;
  final List<TemplateFolder> folders;
  final List<DocumentTemplate> documentTemplates;
  final bool isBuiltIn;
  final DateTime createdAt;

  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.folders,
    this.documentTemplates = const [],
    this.isBuiltIn = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'folders': folders.map((f) => f.toJson()).toList(),
      'documentTemplates': documentTemplates.map((t) => t.toJson()).toList(),
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectTemplate.fromJson(Map<String, dynamic> json) {
    return ProjectTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ProjectTemplateType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ProjectTemplateType.blank,
      ),
      folders: (json['folders'] as List)
          .map((f) => TemplateFolder.fromJson(f as Map<String, dynamic>))
          .toList(),
      documentTemplates: (json['documentTemplates'] as List?)
              ?.map((t) => DocumentTemplate.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Type of project template
enum ProjectTemplateType {
  blank,
  novel,
  shortStory,
  screenplay,
  nonFiction,
  thesis,
  blog,
  custom,
}

extension ProjectTemplateTypeExtension on ProjectTemplateType {
  String get displayName {
    switch (this) {
      case ProjectTemplateType.blank:
        return 'Blank';
      case ProjectTemplateType.novel:
        return 'Novel';
      case ProjectTemplateType.shortStory:
        return 'Short Story';
      case ProjectTemplateType.screenplay:
        return 'Screenplay';
      case ProjectTemplateType.nonFiction:
        return 'Non-Fiction';
      case ProjectTemplateType.thesis:
        return 'Thesis';
      case ProjectTemplateType.blog:
        return 'Blog';
      case ProjectTemplateType.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case ProjectTemplateType.blank:
        return 'Start with a clean slate';
      case ProjectTemplateType.novel:
        return 'Structure for writing a novel with chapters and scenes';
      case ProjectTemplateType.shortStory:
        return 'Compact structure for short fiction';
      case ProjectTemplateType.screenplay:
        return 'Industry-standard screenplay format';
      case ProjectTemplateType.nonFiction:
        return 'Organized structure for non-fiction writing';
      case ProjectTemplateType.thesis:
        return 'Academic thesis or dissertation format';
      case ProjectTemplateType.blog:
        return 'Simple structure for blog posts';
      case ProjectTemplateType.custom:
        return 'User-created template';
    }
  }

  IconData get icon {
    switch (this) {
      case ProjectTemplateType.blank:
        return Icons.note_add;
      case ProjectTemplateType.novel:
        return Icons.auto_stories;
      case ProjectTemplateType.shortStory:
        return Icons.short_text;
      case ProjectTemplateType.screenplay:
        return Icons.movie_creation;
      case ProjectTemplateType.nonFiction:
        return Icons.article;
      case ProjectTemplateType.thesis:
        return Icons.school;
      case ProjectTemplateType.blog:
        return Icons.rss_feed;
      case ProjectTemplateType.custom:
        return Icons.dashboard_customize;
    }
  }
}

/// Represents a folder in a project template
class TemplateFolder {
  final String name;
  final List<TemplateFolder> subfolders;
  final List<TemplateDocument> documents;

  const TemplateFolder({
    required this.name,
    this.subfolders = const [],
    this.documents = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subfolders': subfolders.map((f) => f.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
    };
  }

  factory TemplateFolder.fromJson(Map<String, dynamic> json) {
    return TemplateFolder(
      name: json['name'] as String,
      subfolders: (json['subfolders'] as List?)
              ?.map((f) => TemplateFolder.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      documents: (json['documents'] as List?)
              ?.map((d) => TemplateDocument.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Represents a document in a project template
class TemplateDocument {
  final String name;
  final String content;
  final DocumentTemplateType type;

  const TemplateDocument({
    required this.name,
    this.content = '',
    this.type = DocumentTemplateType.general,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'content': content,
      'type': type.name,
    };
  }

  factory TemplateDocument.fromJson(Map<String, dynamic> json) {
    return TemplateDocument(
      name: json['name'] as String,
      content: json['content'] as String? ?? '',
      type: DocumentTemplateType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => DocumentTemplateType.general,
      ),
    );
  }
}
