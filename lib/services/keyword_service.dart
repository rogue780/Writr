import 'package:flutter/material.dart';
import '../models/keyword.dart';

/// Service for managing project keywords
class KeywordService extends ChangeNotifier {
  /// All keywords in the project
  final List<Keyword> _keywords = [];

  /// Document keyword associations
  final Map<String, DocumentKeywords> _documentKeywords = {};

  /// Get all keywords
  List<Keyword> get keywords => List.unmodifiable(_keywords);

  /// Get root keywords (no parent)
  List<Keyword> get rootKeywords =>
      _keywords.where((k) => k.parentId == null).toList();

  /// Get children of a keyword
  List<Keyword> getChildren(String parentId) =>
      _keywords.where((k) => k.parentId == parentId).toList();

  /// Get keyword by ID
  Keyword? getKeyword(String id) {
    try {
      return _keywords.firstWhere((k) => k.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get keywords for a document
  List<Keyword> getKeywordsForDocument(String documentId) {
    final docKeywords = _documentKeywords[documentId];
    if (docKeywords == null) return [];

    return docKeywords.keywordIds
        .map((id) => getKeyword(id))
        .whereType<Keyword>()
        .toList();
  }

  /// Get documents with a specific keyword
  List<String> getDocumentsWithKeyword(String keywordId) {
    return _documentKeywords.entries
        .where((entry) => entry.value.keywordIds.contains(keywordId))
        .map((entry) => entry.key)
        .toList();
  }

  /// Create a new keyword
  Keyword createKeyword({
    required String name,
    int? colorValue,
    String? parentId,
  }) {
    final keyword = Keyword(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorValue: colorValue ?? KeywordColors.getColorValue(_keywords.length),
      parentId: parentId,
      createdAt: DateTime.now(),
    );

    _keywords.add(keyword);
    notifyListeners();
    return keyword;
  }

  /// Update a keyword
  void updateKeyword(Keyword keyword) {
    final index = _keywords.indexWhere((k) => k.id == keyword.id);
    if (index != -1) {
      _keywords[index] = keyword;
      notifyListeners();
    }
  }

  /// Delete a keyword
  void deleteKeyword(String keywordId) {
    // Remove from all documents
    for (final entry in _documentKeywords.entries) {
      if (entry.value.keywordIds.contains(keywordId)) {
        _documentKeywords[entry.key] = entry.value.copyWith(
          keywordIds: entry.value.keywordIds
              .where((id) => id != keywordId)
              .toList(),
        );
      }
    }

    // Remove children keywords
    final children = getChildren(keywordId);
    for (final child in children) {
      deleteKeyword(child.id);
    }

    // Remove keyword
    _keywords.removeWhere((k) => k.id == keywordId);
    notifyListeners();
  }

  /// Assign keyword to document
  void assignKeywordToDocument(String documentId, String keywordId) {
    final existing = _documentKeywords[documentId];
    if (existing != null) {
      if (!existing.keywordIds.contains(keywordId)) {
        _documentKeywords[documentId] = existing.copyWith(
          keywordIds: [...existing.keywordIds, keywordId],
        );
      }
    } else {
      _documentKeywords[documentId] = DocumentKeywords(
        documentId: documentId,
        keywordIds: [keywordId],
      );
    }
    notifyListeners();
  }

  /// Remove keyword from document
  void removeKeywordFromDocument(String documentId, String keywordId) {
    final existing = _documentKeywords[documentId];
    if (existing != null) {
      _documentKeywords[documentId] = existing.copyWith(
        keywordIds: existing.keywordIds.where((id) => id != keywordId).toList(),
      );
      notifyListeners();
    }
  }

  /// Set all keywords for a document
  void setDocumentKeywords(String documentId, List<String> keywordIds) {
    _documentKeywords[documentId] = DocumentKeywords(
      documentId: documentId,
      keywordIds: keywordIds,
    );
    notifyListeners();
  }

  /// Search keywords by name
  List<Keyword> searchKeywords(String query) {
    final lowerQuery = query.toLowerCase();
    return _keywords
        .where((k) => k.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get keyword usage count
  int getKeywordUsageCount(String keywordId) {
    return _documentKeywords.values
        .where((dk) => dk.keywordIds.contains(keywordId))
        .length;
  }

  /// Merge two keywords (move all associations to target)
  void mergeKeywords(String sourceId, String targetId) {
    // Move all document associations
    for (final entry in _documentKeywords.entries) {
      if (entry.value.keywordIds.contains(sourceId)) {
        final newIds = entry.value.keywordIds
            .where((id) => id != sourceId)
            .toList();
        if (!newIds.contains(targetId)) {
          newIds.add(targetId);
        }
        _documentKeywords[entry.key] = entry.value.copyWith(keywordIds: newIds);
      }
    }

    // Delete source keyword
    _keywords.removeWhere((k) => k.id == sourceId);
    notifyListeners();
  }

  /// Load keywords from JSON
  void loadKeywords(List<Map<String, dynamic>> data) {
    _keywords.clear();
    for (final item in data) {
      _keywords.add(Keyword.fromJson(item));
    }
    notifyListeners();
  }

  /// Load document keywords from JSON
  void loadDocumentKeywords(List<Map<String, dynamic>> data) {
    _documentKeywords.clear();
    for (final item in data) {
      final dk = DocumentKeywords.fromJson(item);
      _documentKeywords[dk.documentId] = dk;
    }
    notifyListeners();
  }

  /// Export keywords to JSON
  List<Map<String, dynamic>> keywordsToJson() {
    return _keywords.map((k) => k.toJson()).toList();
  }

  /// Export document keywords to JSON
  List<Map<String, dynamic>> documentKeywordsToJson() {
    return _documentKeywords.values.map((dk) => dk.toJson()).toList();
  }

  /// Clear all data
  void clear() {
    _keywords.clear();
    _documentKeywords.clear();
    notifyListeners();
  }

  /// Create default keywords for a new project
  void createDefaultKeywords() {
    final defaults = [
      ('Character', KeywordColors.palette[0]),
      ('Setting', KeywordColors.palette[1]),
      ('Theme', KeywordColors.palette[2]),
      ('Plot Point', KeywordColors.palette[3]),
      ('Conflict', KeywordColors.palette[4]),
      ('Symbolism', KeywordColors.palette[5]),
    ];

    for (final (name, color) in defaults) {
      createKeyword(name: name, colorValue: color.toARGB32());
    }
  }
}
