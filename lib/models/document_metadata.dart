/// Represents the metadata associated with a document in the binder.
class DocumentMetadata {
  /// Unique identifier for this document
  final String documentId;

  /// User-defined label with associated color
  final DocumentLabel? label;

  /// Status of the document (Draft, Revised, Final, etc.)
  final DocumentStatus status;

  /// Brief synopsis/summary of the document
  final String synopsis;

  /// Additional notes about the document (separate from main text)
  final String notes;

  /// Target word count for this document
  final int? wordCountTarget;

  /// Whether to include this document in compile
  final bool includeInCompile;

  /// Custom icon for this document
  final String? customIcon;

  /// Document creation timestamp
  final DateTime createdAt;

  /// Last modified timestamp
  final DateTime modifiedAt;

  DocumentMetadata({
    required this.documentId,
    this.label,
    this.status = DocumentStatus.noStatus,
    this.synopsis = '',
    this.notes = '',
    this.wordCountTarget,
    this.includeInCompile = true,
    this.customIcon,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Create a copy with updated fields
  DocumentMetadata copyWith({
    String? documentId,
    DocumentLabel? label,
    DocumentStatus? status,
    String? synopsis,
    String? notes,
    int? wordCountTarget,
    bool? includeInCompile,
    String? customIcon,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return DocumentMetadata(
      documentId: documentId ?? this.documentId,
      label: label ?? this.label,
      status: status ?? this.status,
      synopsis: synopsis ?? this.synopsis,
      notes: notes ?? this.notes,
      wordCountTarget: wordCountTarget ?? this.wordCountTarget,
      includeInCompile: includeInCompile ?? this.includeInCompile,
      customIcon: customIcon ?? this.customIcon,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'label': label?.toJson(),
      'status': status.name,
      'synopsis': synopsis,
      'notes': notes,
      'wordCountTarget': wordCountTarget,
      'includeInCompile': includeInCompile,
      'customIcon': customIcon,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      documentId: json['documentId'] as String,
      label: json['label'] != null
          ? DocumentLabel.fromJson(json['label'] as Map<String, dynamic>)
          : null,
      status: DocumentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DocumentStatus.noStatus,
      ),
      synopsis: json['synopsis'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      wordCountTarget: json['wordCountTarget'] as int?,
      includeInCompile: json['includeInCompile'] as bool? ?? true,
      customIcon: json['customIcon'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
    );
  }

  /// Create default metadata for a new document
  factory DocumentMetadata.empty(String documentId) {
    return DocumentMetadata(documentId: documentId);
  }
}

/// Represents a user-defined label with color
class DocumentLabel {
  final String name;
  final int colorValue; // ARGB color value

  const DocumentLabel({
    required this.name,
    required this.colorValue,
  });

  /// Get the color as a Color object
  int get color => colorValue;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorValue': colorValue,
    };
  }

  factory DocumentLabel.fromJson(Map<String, dynamic> json) {
    return DocumentLabel(
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    );
  }

  /// Predefined labels
  static const DocumentLabel red = DocumentLabel(
    name: 'Red',
    colorValue: 0xFFE53935,
  );

  static const DocumentLabel orange = DocumentLabel(
    name: 'Orange',
    colorValue: 0xFFFF9800,
  );

  static const DocumentLabel yellow = DocumentLabel(
    name: 'Yellow',
    colorValue: 0xFFFFEB3B,
  );

  static const DocumentLabel green = DocumentLabel(
    name: 'Green',
    colorValue: 0xFF4CAF50,
  );

  static const DocumentLabel blue = DocumentLabel(
    name: 'Blue',
    colorValue: 0xFF2196F3,
  );

  static const DocumentLabel purple = DocumentLabel(
    name: 'Purple',
    colorValue: 0xFF9C27B0,
  );

  static List<DocumentLabel> get predefinedLabels => [
        red,
        orange,
        yellow,
        green,
        blue,
        purple,
      ];
}

/// Document status enum
enum DocumentStatus {
  noStatus('No Status'),
  toDo('To Do'),
  inProgress('In Progress'),
  firstDraft('First Draft'),
  revisedDraft('Revised Draft'),
  finalDraft('Final Draft'),
  done('Done');

  final String displayName;
  const DocumentStatus(this.displayName);
}

/// Project-wide label definitions
class ProjectLabels {
  final List<DocumentLabel> labels;

  ProjectLabels({List<DocumentLabel>? labels})
      : labels = labels ?? DocumentLabel.predefinedLabels;

  Map<String, dynamic> toJson() {
    return {
      'labels': labels.map((l) => l.toJson()).toList(),
    };
  }

  factory ProjectLabels.fromJson(Map<String, dynamic> json) {
    return ProjectLabels(
      labels: (json['labels'] as List<dynamic>?)
              ?.map((l) => DocumentLabel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          DocumentLabel.predefinedLabels,
    );
  }
}

/// Project-wide status definitions
class ProjectStatuses {
  final List<DocumentStatus> statuses;

  ProjectStatuses({List<DocumentStatus>? statuses})
      : statuses = statuses ?? DocumentStatus.values.toList();

  Map<String, dynamic> toJson() {
    return {
      'statuses': statuses.map((s) => s.name).toList(),
    };
  }

  factory ProjectStatuses.fromJson(Map<String, dynamic> json) {
    return ProjectStatuses(
      statuses: (json['statuses'] as List<dynamic>?)
              ?.map((s) => DocumentStatus.values.firstWhere(
                    (status) => status.name == s,
                    orElse: () => DocumentStatus.noStatus,
                  ))
              .toList() ??
          DocumentStatus.values.toList(),
    );
  }
}
