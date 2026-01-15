import 'package:flutter/foundation.dart';
import '../models/scrivener_project.dart';
import '../models/search_result.dart';

/// Service for searching within a Scrivener project
class SearchService extends ChangeNotifier {
  SearchResults? _lastResults;
  bool _isSearching = false;
  String? _error;

  SearchResults? get lastResults => _lastResults;
  bool get isSearching => _isSearching;
  String? get error => _error;

  /// Perform a search across the project
  Future<SearchResults> search(
    ScrivenerProject project,
    String query, {
    SearchOptions options = const SearchOptions(),
    String? currentFolderId,
    List<String>? selectedDocumentIds,
  }) async {
    if (query.isEmpty) {
      return SearchResults(
        query: query,
        options: options,
        results: [],
        searchDuration: Duration.zero,
        searchedAt: DateTime.now(),
      );
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      final results = <DocumentSearchResult>[];

      // Build the search pattern
      final pattern = _buildSearchPattern(query, options);

      // Get documents to search based on scope
      final documentsToSearch = _getDocumentsToSearch(
        project,
        options.scope,
        currentFolderId,
        selectedDocumentIds,
      );

      // Search each document
      for (final item in documentsToSearch) {
        final documentResults = _searchDocument(
          item,
          project,
          pattern,
          options,
        );

        if (documentResults.hasMatches) {
          results.add(documentResults);
        }
      }

      stopwatch.stop();

      _lastResults = SearchResults(
        query: query,
        options: options,
        results: results,
        searchDuration: stopwatch.elapsed,
        searchedAt: DateTime.now(),
      );

      _isSearching = false;
      notifyListeners();

      return _lastResults!;
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();

      return SearchResults(
        query: query,
        options: options,
        results: [],
        searchDuration: stopwatch.elapsed,
        searchedAt: DateTime.now(),
      );
    }
  }

  /// Build regex pattern from query and options
  RegExp _buildSearchPattern(String query, SearchOptions options) {
    String pattern;

    if (options.useRegex) {
      pattern = query;
    } else {
      // Escape regex special characters
      pattern = RegExp.escape(query);
    }

    if (options.wholeWord) {
      pattern = r'\b' + pattern + r'\b';
    }

    return RegExp(
      pattern,
      caseSensitive: options.caseSensitive,
      multiLine: true,
    );
  }

  /// Get list of documents to search based on scope
  List<_DocumentWithPath> _getDocumentsToSearch(
    ScrivenerProject project,
    SearchScope scope,
    String? currentFolderId,
    List<String>? selectedDocumentIds,
  ) {
    final documents = <_DocumentWithPath>[];

    void collectDocuments(List<BinderItem> items, String path, bool inManuscript, bool inResearch) {
      for (final item in items) {
        final itemPath = path.isEmpty ? item.title : '$path / ${item.title}';
        final isManuscript = item.title.toLowerCase() == 'manuscript' || inManuscript;
        final isResearch = item.title.toLowerCase() == 'research' || inResearch;

        // Check if this document should be included based on scope
        bool shouldInclude = false;
        switch (scope) {
          case SearchScope.entireProject:
            shouldInclude = true;
            break;
          case SearchScope.manuscript:
            shouldInclude = isManuscript;
            break;
          case SearchScope.research:
            shouldInclude = isResearch;
            break;
          case SearchScope.currentFolder:
            shouldInclude = currentFolderId != null &&
                           _isInFolder(project.binderItems, currentFolderId, item.id);
            break;
          case SearchScope.selection:
            shouldInclude = selectedDocumentIds?.contains(item.id) ?? false;
            break;
        }

        if (shouldInclude && !item.isFolder) {
          documents.add(_DocumentWithPath(item: item, path: itemPath));
        }

        if (item.children.isNotEmpty) {
          collectDocuments(item.children, itemPath, isManuscript, isResearch);
        }
      }
    }

    collectDocuments(project.binderItems, '', false, false);
    return documents;
  }

  /// Check if a document is in a specific folder
  bool _isInFolder(List<BinderItem> items, String folderId, String documentId) {
    for (final item in items) {
      if (item.id == folderId) {
        return _containsDocument(item.children, documentId);
      }
      if (item.children.isNotEmpty) {
        if (_isInFolder(item.children, folderId, documentId)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if a list of items contains a document
  bool _containsDocument(List<BinderItem> items, String documentId) {
    for (final item in items) {
      if (item.id == documentId) return true;
      if (_containsDocument(item.children, documentId)) return true;
    }
    return false;
  }

  /// Search within a single document
  DocumentSearchResult _searchDocument(
    _DocumentWithPath doc,
    ScrivenerProject project,
    RegExp pattern,
    SearchOptions options,
  ) {
    final matches = <SearchMatch>[];
    SearchLocation? location;

    // Search in title
    if (options.searchInTitles) {
      final titleMatches = _findMatches(doc.item.title, pattern, 1);
      if (titleMatches.isNotEmpty) {
        matches.addAll(titleMatches);
        location = SearchLocation.title;
      }
    }

    // Search in content
    if (options.searchInContent) {
      final content = project.textContents[doc.item.id] ?? '';
      final contentMatches = _findMatches(content, pattern, 1);
      if (contentMatches.isNotEmpty) {
        matches.addAll(contentMatches);
        location ??= SearchLocation.content;
      }
    }

    // Search in synopsis
    if (options.searchInSynopsis) {
      final metadata = project.documentMetadata[doc.item.id];
      if (metadata != null && metadata.synopsis.isNotEmpty) {
        final synopsisMatches = _findMatches(metadata.synopsis, pattern, 1);
        if (synopsisMatches.isNotEmpty) {
          matches.addAll(synopsisMatches);
          location ??= SearchLocation.synopsis;
        }
      }
    }

    // Search in notes
    if (options.searchInNotes) {
      final metadata = project.documentMetadata[doc.item.id];
      if (metadata != null && metadata.notes.isNotEmpty) {
        final notesMatches = _findMatches(metadata.notes, pattern, 1);
        if (notesMatches.isNotEmpty) {
          matches.addAll(notesMatches);
          location ??= SearchLocation.notes;
        }
      }
    }

    return DocumentSearchResult(
      documentId: doc.item.id,
      documentTitle: doc.item.title,
      documentPath: doc.path,
      matches: matches,
      location: location ?? SearchLocation.content,
    );
  }

  /// Find all matches in a text
  List<SearchMatch> _findMatches(String text, RegExp pattern, int startLine) {
    final matches = <SearchMatch>[];
    final allMatches = pattern.allMatches(text);

    for (final match in allMatches) {
      // Calculate line number
      final lineNumber = startLine + '\n'.allMatches(text.substring(0, match.start)).length;

      // Get context around the match
      const contextLength = 40;
      final contextStart = (match.start - contextLength).clamp(0, text.length);
      final contextEnd = (match.end + contextLength).clamp(0, text.length);

      var contextBefore = text.substring(contextStart, match.start);
      var contextAfter = text.substring(match.end, contextEnd);

      // Clean up context (remove line breaks, trim)
      contextBefore = contextBefore.replaceAll('\n', ' ');
      contextAfter = contextAfter.replaceAll('\n', ' ');

      // Add ellipsis if truncated
      if (contextStart > 0) {
        contextBefore = '...$contextBefore';
      }
      if (contextEnd < text.length) {
        contextAfter = '$contextAfter...';
      }

      matches.add(SearchMatch(
        startIndex: match.start,
        endIndex: match.end,
        matchedText: match.group(0) ?? '',
        contextBefore: contextBefore,
        contextAfter: contextAfter,
        lineNumber: lineNumber,
      ));
    }

    return matches;
  }

  /// Perform find and replace in a document
  String replaceInDocument(
    String content,
    String query,
    ReplaceOptions replaceOptions, {
    SearchOptions searchOptions = const SearchOptions(),
    bool replaceAll = true,
    int? replaceIndex,
  }) {
    final pattern = _buildSearchPattern(query, searchOptions);

    if (replaceAll) {
      return content.replaceAllMapped(pattern, (match) {
        return _getReplacement(match.group(0)!, replaceOptions);
      });
    } else if (replaceIndex != null) {
      final matches = pattern.allMatches(content).toList();
      if (replaceIndex >= 0 && replaceIndex < matches.length) {
        final match = matches[replaceIndex];
        final replacement = _getReplacement(match.group(0)!, replaceOptions);
        return content.substring(0, match.start) +
            replacement +
            content.substring(match.end);
      }
    }

    return content;
  }

  /// Get replacement text, optionally preserving case
  String _getReplacement(String matched, ReplaceOptions options) {
    if (!options.preserveCase) {
      return options.replaceWith;
    }

    // Preserve case: if matched is all upper, make replacement all upper
    // if matched starts with upper, capitalize replacement, etc.
    final replacement = options.replaceWith;

    if (matched == matched.toUpperCase()) {
      return replacement.toUpperCase();
    } else if (matched.isNotEmpty &&
        matched[0] == matched[0].toUpperCase() &&
        matched.substring(1) == matched.substring(1).toLowerCase()) {
      // Title case
      if (replacement.isEmpty) return replacement;
      return replacement[0].toUpperCase() + replacement.substring(1).toLowerCase();
    }

    return replacement;
  }

  /// Clear search results
  void clearResults() {
    _lastResults = null;
    _error = null;
    notifyListeners();
  }
}

/// Helper class to hold document with its binder path
class _DocumentWithPath {
  final BinderItem item;
  final String path;

  _DocumentWithPath({required this.item, required this.path});
}
