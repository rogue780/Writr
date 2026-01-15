/// Represents a snapshot of a document's content at a point in time.
class DocumentSnapshot {
  final String id;
  final String documentId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? note;

  const DocumentSnapshot({
    required this.id,
    required this.documentId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.note,
  });

  /// Creates a new snapshot with the given parameters.
  factory DocumentSnapshot.create({
    required String documentId,
    required String title,
    required String content,
    String? note,
  }) {
    return DocumentSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: documentId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      note: note,
    );
  }

  /// Creates a copy with updated fields.
  DocumentSnapshot copyWith({
    String? id,
    String? documentId,
    String? title,
    String? content,
    DateTime? createdAt,
    String? note,
  }) {
    return DocumentSnapshot(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  /// Converts to JSON map for serialization.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  /// Creates from JSON map.
  factory DocumentSnapshot.fromJson(Map<String, dynamic> json) {
    return DocumentSnapshot(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }

  /// Formats the creation date for display.
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
    }
  }

  /// Gets word count of the snapshot content.
  int get wordCount {
    if (content.isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }
}

/// Represents a diff between two text versions.
class TextDiff {
  final List<DiffSegment> segments;

  const TextDiff(this.segments);

  /// Computes a simple diff between old and new text.
  factory TextDiff.compute(String oldText, String newText) {
    final segments = <DiffSegment>[];

    // Split into lines for line-by-line comparison
    final oldLines = oldText.split('\n');
    final newLines = newText.split('\n');

    int oldIndex = 0;
    int newIndex = 0;

    while (oldIndex < oldLines.length || newIndex < newLines.length) {
      if (oldIndex >= oldLines.length) {
        // Remaining new lines are additions
        segments.add(DiffSegment(
          text: newLines[newIndex],
          type: DiffType.added,
        ));
        newIndex++;
      } else if (newIndex >= newLines.length) {
        // Remaining old lines are deletions
        segments.add(DiffSegment(
          text: oldLines[oldIndex],
          type: DiffType.removed,
        ));
        oldIndex++;
      } else if (oldLines[oldIndex] == newLines[newIndex]) {
        // Lines match
        segments.add(DiffSegment(
          text: oldLines[oldIndex],
          type: DiffType.unchanged,
        ));
        oldIndex++;
        newIndex++;
      } else {
        // Lines differ - check if it's a modification or add/remove
        final oldLineInNew = newLines.indexOf(oldLines[oldIndex], newIndex);
        final newLineInOld = oldLines.indexOf(newLines[newIndex], oldIndex);

        if (oldLineInNew == -1 && newLineInOld == -1) {
          // Both lines are unique - treat as modification
          segments.add(DiffSegment(
            text: oldLines[oldIndex],
            type: DiffType.removed,
          ));
          segments.add(DiffSegment(
            text: newLines[newIndex],
            type: DiffType.added,
          ));
          oldIndex++;
          newIndex++;
        } else if (oldLineInNew != -1 && (newLineInOld == -1 || oldLineInNew - newIndex < newLineInOld - oldIndex)) {
          // Old line appears later in new - new lines are additions
          segments.add(DiffSegment(
            text: newLines[newIndex],
            type: DiffType.added,
          ));
          newIndex++;
        } else {
          // New line appears later in old - old lines are deletions
          segments.add(DiffSegment(
            text: oldLines[oldIndex],
            type: DiffType.removed,
          ));
          oldIndex++;
        }
      }
    }

    return TextDiff(segments);
  }

  /// Gets count of added lines.
  int get addedCount => segments.where((s) => s.type == DiffType.added).length;

  /// Gets count of removed lines.
  int get removedCount => segments.where((s) => s.type == DiffType.removed).length;

  /// Gets count of unchanged lines.
  int get unchangedCount => segments.where((s) => s.type == DiffType.unchanged).length;

  /// Returns true if there are any changes.
  bool get hasChanges => addedCount > 0 || removedCount > 0;
}

/// Represents a segment of a diff.
class DiffSegment {
  final String text;
  final DiffType type;

  const DiffSegment({
    required this.text,
    required this.type,
  });
}

/// Type of diff segment.
enum DiffType {
  unchanged,
  added,
  removed,
}
