import 'package:flutter/foundation.dart';
import '../models/footnote.dart';

/// Service for managing document footnotes and inline notes
class FootnoteService extends ChangeNotifier {
  /// Footnotes indexed by document ID
  final Map<String, List<DocumentFootnote>> _footnotesByDocument = {};

  /// Footnote settings for the project
  FootnoteSettings _settings = const FootnoteSettings();

  /// Get current footnote settings
  FootnoteSettings get settings => _settings;

  /// Update footnote settings
  void updateSettings(FootnoteSettings newSettings) {
    _settings = newSettings;
    // Renumber all footnotes based on new settings
    _renumberAllFootnotes();
    notifyListeners();
  }

  /// Get all footnotes for a document
  List<DocumentFootnote> getFootnotesForDocument(String documentId) {
    return List.unmodifiable(_footnotesByDocument[documentId] ?? []);
  }

  /// Get all footnotes across the project
  List<DocumentFootnote> get allFootnotes {
    return _footnotesByDocument.values.expand((f) => f).toList();
  }

  /// Get footnotes by type for a document
  List<DocumentFootnote> getFootnotesByType(
    String documentId,
    FootnoteType type,
  ) {
    return getFootnotesForDocument(documentId)
        .where((f) => f.type == type)
        .toList();
  }

  /// Get footnote at a specific position
  DocumentFootnote? getFootnoteAtPosition(String documentId, int position) {
    final footnotes = getFootnotesForDocument(documentId);
    for (final footnote in footnotes) {
      if (footnote.anchorOffset == position) {
        return footnote;
      }
    }
    return null;
  }

  /// Get footnote near a position (within threshold)
  DocumentFootnote? getFootnoteNearPosition(
    String documentId,
    int position, {
    int threshold = 2,
  }) {
    final footnotes = getFootnotesForDocument(documentId);
    for (final footnote in footnotes) {
      if ((footnote.anchorOffset - position).abs() <= threshold) {
        return footnote;
      }
    }
    return null;
  }

  /// Add a new footnote
  void addFootnote(DocumentFootnote footnote) {
    final documentFootnotes = _footnotesByDocument[footnote.documentId] ?? [];
    _footnotesByDocument[footnote.documentId] = [...documentFootnotes, footnote];
    _renumberFootnotesInDocument(footnote.documentId);
    notifyListeners();
  }

  /// Create and add a new footnote
  DocumentFootnote createFootnote({
    required String documentId,
    required int anchorOffset,
    required String content,
    FootnoteType type = FootnoteType.footnote,
  }) {
    final footnote = DocumentFootnote.create(
      documentId: documentId,
      anchorOffset: anchorOffset,
      content: content,
      type: type,
    );
    addFootnote(footnote);
    return footnote;
  }

  /// Update a footnote's content
  void updateFootnoteContent(
    String documentId,
    String footnoteId,
    String newContent,
  ) {
    _updateFootnote(documentId, footnoteId, (f) => f.withContent(newContent));
  }

  /// Change a footnote's type
  void changeFootnoteType(
    String documentId,
    String footnoteId,
    FootnoteType newType,
  ) {
    _updateFootnote(
      documentId,
      footnoteId,
      (f) => f.copyWith(type: newType),
    );
    _renumberFootnotesInDocument(documentId);
  }

  /// Delete a footnote
  void deleteFootnote(String documentId, String footnoteId) {
    final footnotes = _footnotesByDocument[documentId];
    if (footnotes != null) {
      _footnotesByDocument[documentId] =
          footnotes.where((f) => f.id != footnoteId).toList();
      _renumberFootnotesInDocument(documentId);
      notifyListeners();
    }
  }

  /// Delete all footnotes for a document
  void deleteAllFootnotesForDocument(String documentId) {
    _footnotesByDocument.remove(documentId);
    notifyListeners();
  }

  /// Adjust footnote offsets when text changes in a document
  void adjustOffsetsForTextChange(
    String documentId,
    int changePosition,
    int delta,
  ) {
    final footnotes = _footnotesByDocument[documentId];
    if (footnotes == null || footnotes.isEmpty) return;

    final adjustedFootnotes = footnotes
        .map((f) => f.adjustOffset(changePosition, delta))
        .toList();

    _footnotesByDocument[documentId] = adjustedFootnotes;
    notifyListeners();
  }

  /// Renumber footnotes in a document based on their position
  void _renumberFootnotesInDocument(String documentId) {
    final footnotes = _footnotesByDocument[documentId];
    if (footnotes == null || footnotes.isEmpty) return;

    // Sort by anchor offset
    final sorted = [...footnotes]
      ..sort((a, b) => a.anchorOffset.compareTo(b.anchorOffset));

    // Renumber each type separately
    final numberedFootnotes = <DocumentFootnote>[];
    final typeCounters = <FootnoteType, int>{};

    for (final footnote in sorted) {
      if (footnote.type == FootnoteType.footnote ||
          footnote.type == FootnoteType.endnote) {
        final count = (typeCounters[footnote.type] ?? 0) + 1;
        typeCounters[footnote.type] = count;
        numberedFootnotes.add(footnote.withNumber(count));
      } else {
        // Inline notes and annotations don't get numbered
        numberedFootnotes.add(footnote.copyWith(number: null));
      }
    }

    _footnotesByDocument[documentId] = numberedFootnotes;
  }

  /// Renumber all footnotes across the project
  void _renumberAllFootnotes() {
    for (final documentId in _footnotesByDocument.keys) {
      _renumberFootnotesInDocument(documentId);
    }
  }

  /// Get formatted footnote number
  String getFormattedNumber(DocumentFootnote footnote) {
    if (footnote.number == null) return '';
    return _settings.formatNumber(footnote.number!);
  }

  /// Load footnotes from JSON data
  void loadFootnotes(Map<String, List<Map<String, dynamic>>> data) {
    _footnotesByDocument.clear();
    for (final entry in data.entries) {
      _footnotesByDocument[entry.key] =
          entry.value.map((json) => DocumentFootnote.fromJson(json)).toList();
    }
    notifyListeners();
  }

  /// Load footnote settings from JSON
  void loadSettings(Map<String, dynamic> json) {
    _settings = FootnoteSettings.fromJson(json);
    notifyListeners();
  }

  /// Export all footnotes to JSON
  Map<String, List<Map<String, dynamic>>> toJson() {
    return _footnotesByDocument.map(
      (key, value) => MapEntry(key, value.map((f) => f.toJson()).toList()),
    );
  }

  /// Export settings to JSON
  Map<String, dynamic> settingsToJson() {
    return _settings.toJson();
  }

  /// Get footnote count for a document
  int getFootnoteCount(String documentId) {
    return _footnotesByDocument[documentId]?.length ?? 0;
  }

  /// Get total footnote count across all documents
  int get totalFootnoteCount {
    return _footnotesByDocument.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Get documents that have footnotes
  List<String> get documentsWithFootnotes {
    return _footnotesByDocument.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();
  }

  /// Clear all footnotes
  void clear() {
    _footnotesByDocument.clear();
    notifyListeners();
  }

  /// Helper to update a specific footnote
  void _updateFootnote(
    String documentId,
    String footnoteId,
    DocumentFootnote Function(DocumentFootnote) updater,
  ) {
    final footnotes = _footnotesByDocument[documentId];
    if (footnotes == null) return;

    final index = footnotes.indexWhere((f) => f.id == footnoteId);
    if (index == -1) return;

    final updatedFootnotes = [...footnotes];
    updatedFootnotes[index] = updater(footnotes[index]);
    _footnotesByDocument[documentId] = updatedFootnotes;
    notifyListeners();
  }

  /// Get all footnotes for compilation (in order by document and position)
  List<DocumentFootnote> getFootnotesForCompilation(List<String> documentIds) {
    final allFootnotes = <DocumentFootnote>[];

    for (final docId in documentIds) {
      final docFootnotes = getFootnotesForDocument(docId)
          .where((f) =>
              f.type == FootnoteType.footnote || f.type == FootnoteType.endnote)
          .toList()
        ..sort((a, b) => a.anchorOffset.compareTo(b.anchorOffset));
      allFootnotes.addAll(docFootnotes);
    }

    // Renumber for compilation based on restart mode
    if (_settings.restartMode == FootnoteRestartMode.continuous) {
      int counter = 0;
      return allFootnotes.map((f) {
        counter++;
        return f.withNumber(counter);
      }).toList();
    }

    return allFootnotes;
  }

  /// Get inline notes for a document (for display, not for compilation)
  List<DocumentFootnote> getInlineNotes(String documentId) {
    return getFootnotesByType(documentId, FootnoteType.inlineNote);
  }

  /// Get annotations for a document
  List<DocumentFootnote> getAnnotations(String documentId) {
    return getFootnotesByType(documentId, FootnoteType.annotation);
  }
}
