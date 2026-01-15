import 'package:flutter/foundation.dart';
import '../models/comment.dart';

/// Service for managing document comments
class CommentService extends ChangeNotifier {
  /// Comments indexed by document ID
  final Map<String, List<DocumentComment>> _commentsByDocument = {};

  /// Get all comments for a document
  List<DocumentComment> getCommentsForDocument(String documentId) {
    return List.unmodifiable(_commentsByDocument[documentId] ?? []);
  }

  /// Get all comments across the project
  List<DocumentComment> get allComments {
    return _commentsByDocument.values.expand((c) => c).toList();
  }

  /// Get unresolved comments for a document
  List<DocumentComment> getUnresolvedComments(String documentId) {
    return getCommentsForDocument(documentId)
        .where((c) => !c.isResolved)
        .toList();
  }

  /// Get resolved comments for a document
  List<DocumentComment> getResolvedComments(String documentId) {
    return getCommentsForDocument(documentId)
        .where((c) => c.isResolved)
        .toList();
  }

  /// Get comments that overlap with a text range
  List<DocumentComment> getCommentsInRange(
    String documentId,
    int startOffset,
    int endOffset,
  ) {
    return getCommentsForDocument(documentId)
        .where((c) => c.overlapsRange(startOffset, endOffset))
        .toList();
  }

  /// Get comment at a specific position
  DocumentComment? getCommentAtPosition(String documentId, int position) {
    final comments = getCommentsForDocument(documentId);
    for (final comment in comments) {
      if (comment.containsPosition(position)) {
        return comment;
      }
    }
    return null;
  }

  /// Add a new comment
  void addComment(DocumentComment comment) {
    final documentComments = _commentsByDocument[comment.documentId] ?? [];
    _commentsByDocument[comment.documentId] = [...documentComments, comment];
    notifyListeners();
  }

  /// Create and add a new comment
  DocumentComment createComment({
    required String documentId,
    required int startOffset,
    required int endOffset,
    required String commentText,
    String? author,
    int? colorValue,
  }) {
    final comment = DocumentComment.create(
      documentId: documentId,
      startOffset: startOffset,
      endOffset: endOffset,
      commentText: commentText,
      author: author,
      colorValue: colorValue,
    );
    addComment(comment);
    return comment;
  }

  /// Update a comment's text
  void updateCommentText(String documentId, String commentId, String newText) {
    _updateComment(documentId, commentId, (c) => c.withText(newText));
  }

  /// Resolve or unresolve a comment
  void setCommentResolved(String documentId, String commentId, bool resolved) {
    _updateComment(documentId, commentId, (c) => c.withResolved(resolved));
  }

  /// Add a reply to a comment
  void addReply(String documentId, String commentId, CommentReply reply) {
    _updateComment(documentId, commentId, (c) => c.withReply(reply));
  }

  /// Create and add a reply to a comment
  CommentReply createReply({
    required String documentId,
    required String commentId,
    required String text,
    String? author,
  }) {
    final reply = CommentReply.create(text: text, author: author);
    addReply(documentId, commentId, reply);
    return reply;
  }

  /// Remove a reply from a comment
  void removeReply(String documentId, String commentId, String replyId) {
    _updateComment(documentId, commentId, (c) => c.withoutReply(replyId));
  }

  /// Delete a comment
  void deleteComment(String documentId, String commentId) {
    final comments = _commentsByDocument[documentId];
    if (comments != null) {
      _commentsByDocument[documentId] =
          comments.where((c) => c.id != commentId).toList();
      notifyListeners();
    }
  }

  /// Delete all comments for a document
  void deleteAllCommentsForDocument(String documentId) {
    _commentsByDocument.remove(documentId);
    notifyListeners();
  }

  /// Adjust comment offsets when text changes in a document
  void adjustOffsetsForTextChange(
    String documentId,
    int changePosition,
    int delta,
  ) {
    final comments = _commentsByDocument[documentId];
    if (comments == null || comments.isEmpty) return;

    final adjustedComments = <DocumentComment>[];
    for (final comment in comments) {
      final adjusted = comment.adjustOffsets(changePosition, delta);
      // Only keep comments that still have valid ranges
      if (adjusted.startOffset < adjusted.endOffset) {
        adjustedComments.add(adjusted);
      }
    }

    _commentsByDocument[documentId] = adjustedComments;
    notifyListeners();
  }

  /// Load comments from JSON data
  void loadComments(Map<String, List<Map<String, dynamic>>> data) {
    _commentsByDocument.clear();
    for (final entry in data.entries) {
      _commentsByDocument[entry.key] =
          entry.value.map((json) => DocumentComment.fromJson(json)).toList();
    }
    notifyListeners();
  }

  /// Export all comments to JSON
  Map<String, List<Map<String, dynamic>>> toJson() {
    return _commentsByDocument.map(
      (key, value) => MapEntry(key, value.map((c) => c.toJson()).toList()),
    );
  }

  /// Get comment count for a document
  int getCommentCount(String documentId) {
    return _commentsByDocument[documentId]?.length ?? 0;
  }

  /// Get total comment count across all documents
  int get totalCommentCount {
    return _commentsByDocument.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Get documents that have comments
  List<String> get documentsWithComments {
    return _commentsByDocument.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  /// Clear all comments
  void clear() {
    _commentsByDocument.clear();
    notifyListeners();
  }

  /// Helper to update a specific comment
  void _updateComment(
    String documentId,
    String commentId,
    DocumentComment Function(DocumentComment) updater,
  ) {
    final comments = _commentsByDocument[documentId];
    if (comments == null) return;

    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final updatedComments = [...comments];
    updatedComments[index] = updater(comments[index]);
    _commentsByDocument[documentId] = updatedComments;
    notifyListeners();
  }
}
