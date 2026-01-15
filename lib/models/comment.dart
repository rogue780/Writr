/// Represents an inline comment attached to a text range in a document
class DocumentComment {
  final String id;
  final String documentId;
  final int startOffset;
  final int endOffset;
  final String commentText;
  final String? author;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isResolved;
  final List<CommentReply> replies;
  final int colorValue;

  const DocumentComment({
    required this.id,
    required this.documentId,
    required this.startOffset,
    required this.endOffset,
    required this.commentText,
    this.author,
    required this.createdAt,
    required this.modifiedAt,
    this.isResolved = false,
    this.replies = const [],
    this.colorValue = 0xFFFFF176, // Default yellow highlight
  });

  /// Create a new comment
  factory DocumentComment.create({
    required String documentId,
    required int startOffset,
    required int endOffset,
    required String commentText,
    String? author,
    int? colorValue,
  }) {
    final now = DateTime.now();
    return DocumentComment(
      id: '${now.millisecondsSinceEpoch}_comment',
      documentId: documentId,
      startOffset: startOffset,
      endOffset: endOffset,
      commentText: commentText,
      author: author,
      createdAt: now,
      modifiedAt: now,
      colorValue: colorValue ?? 0xFFFFF176,
    );
  }

  /// Get the length of the highlighted text
  int get highlightLength => endOffset - startOffset;

  /// Check if this comment overlaps with a text range
  bool overlapsRange(int start, int end) {
    return startOffset < end && endOffset > start;
  }

  /// Check if a position is within this comment's range
  bool containsPosition(int position) {
    return position >= startOffset && position <= endOffset;
  }

  /// Add a reply to this comment
  DocumentComment withReply(CommentReply reply) {
    return copyWith(
      replies: [...replies, reply],
      modifiedAt: DateTime.now(),
    );
  }

  /// Remove a reply from this comment
  DocumentComment withoutReply(String replyId) {
    return copyWith(
      replies: replies.where((r) => r.id != replyId).toList(),
      modifiedAt: DateTime.now(),
    );
  }

  /// Mark as resolved/unresolved
  DocumentComment withResolved(bool resolved) {
    return copyWith(
      isResolved: resolved,
      modifiedAt: DateTime.now(),
    );
  }

  /// Update the comment text
  DocumentComment withText(String text) {
    return copyWith(
      commentText: text,
      modifiedAt: DateTime.now(),
    );
  }

  /// Adjust offsets when text is inserted/deleted before this comment
  DocumentComment adjustOffsets(int changePosition, int delta) {
    if (changePosition >= endOffset) {
      // Change is after this comment, no adjustment needed
      return this;
    }

    if (changePosition <= startOffset) {
      // Change is before this comment, shift both offsets
      return copyWith(
        startOffset: (startOffset + delta).clamp(0, double.maxFinite.toInt()),
        endOffset: (endOffset + delta).clamp(0, double.maxFinite.toInt()),
      );
    }

    // Change is within or overlapping this comment
    if (delta > 0) {
      // Text inserted within comment, expand the comment
      return copyWith(
        endOffset: endOffset + delta,
      );
    } else {
      // Text deleted within comment
      final deleteEnd = changePosition - delta; // delta is negative
      if (deleteEnd >= endOffset) {
        // Deletion extends past comment end, shrink to change position
        return copyWith(
          endOffset: changePosition,
        );
      } else {
        // Deletion is within comment, shrink by delta
        return copyWith(
          endOffset: endOffset + delta,
        );
      }
    }
  }

  /// Copy with updated fields
  DocumentComment copyWith({
    int? startOffset,
    int? endOffset,
    String? commentText,
    String? author,
    DateTime? modifiedAt,
    bool? isResolved,
    List<CommentReply>? replies,
    int? colorValue,
  }) {
    return DocumentComment(
      id: id,
      documentId: documentId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      commentText: commentText ?? this.commentText,
      author: author ?? this.author,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isResolved: isResolved ?? this.isResolved,
      replies: replies ?? this.replies,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'startOffset': startOffset,
      'endOffset': endOffset,
      'commentText': commentText,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isResolved': isResolved,
      'replies': replies.map((r) => r.toJson()).toList(),
      'colorValue': colorValue,
    };
  }

  /// Create from JSON
  factory DocumentComment.fromJson(Map<String, dynamic> json) {
    return DocumentComment(
      id: json['id'] as String,
      documentId: json['documentId'] as String,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
      commentText: json['commentText'] as String,
      author: json['author'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      isResolved: json['isResolved'] as bool? ?? false,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((r) => CommentReply.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      colorValue: json['colorValue'] as int? ?? 0xFFFFF176,
    );
  }
}

/// A reply to a comment
class CommentReply {
  final String id;
  final String text;
  final String? author;
  final DateTime createdAt;

  const CommentReply({
    required this.id,
    required this.text,
    this.author,
    required this.createdAt,
  });

  /// Create a new reply
  factory CommentReply.create({
    required String text,
    String? author,
  }) {
    return CommentReply(
      id: '${DateTime.now().millisecondsSinceEpoch}_reply',
      text: text,
      author: author,
      createdAt: DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory CommentReply.fromJson(Map<String, dynamic> json) {
    return CommentReply(
      id: json['id'] as String,
      text: json['text'] as String,
      author: json['author'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Predefined comment highlight colors
class CommentColors {
  static const int yellow = 0xFFFFF176;
  static const int pink = 0xFFF48FB1;
  static const int blue = 0xFF90CAF9;
  static const int green = 0xFFA5D6A7;
  static const int orange = 0xFFFFCC80;
  static const int purple = 0xFFCE93D8;

  static const List<int> all = [
    yellow,
    pink,
    blue,
    green,
    orange,
    purple,
  ];

  static String getName(int color) {
    switch (color) {
      case yellow:
        return 'Yellow';
      case pink:
        return 'Pink';
      case blue:
        return 'Blue';
      case green:
        return 'Green';
      case orange:
        return 'Orange';
      case purple:
        return 'Purple';
      default:
        return 'Custom';
    }
  }
}
