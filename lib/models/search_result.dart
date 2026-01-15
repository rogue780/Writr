/// Represents a single search match within a document
class SearchMatch {
  final int startIndex;
  final int endIndex;
  final String matchedText;
  final String contextBefore;
  final String contextAfter;
  final int lineNumber;

  const SearchMatch({
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
    required this.contextBefore,
    required this.contextAfter,
    required this.lineNumber,
  });

  /// Get the full context string with the match highlighted
  String get contextWithMatch => '$contextBefore$matchedText$contextAfter';
}

/// Represents search results for a single document
class DocumentSearchResult {
  final String documentId;
  final String documentTitle;
  final String documentPath; // Path in binder hierarchy
  final List<SearchMatch> matches;
  final SearchLocation location;

  const DocumentSearchResult({
    required this.documentId,
    required this.documentTitle,
    required this.documentPath,
    required this.matches,
    required this.location,
  });

  int get matchCount => matches.length;

  /// Check if this result has any matches
  bool get hasMatches => matches.isNotEmpty;
}

/// Where the search match was found
enum SearchLocation {
  content('Content'),
  title('Title'),
  synopsis('Synopsis'),
  notes('Notes'),
  metadata('Metadata');

  final String displayName;
  const SearchLocation(this.displayName);
}

/// Complete search results for a query
class SearchResults {
  final String query;
  final SearchOptions options;
  final List<DocumentSearchResult> results;
  final Duration searchDuration;
  final DateTime searchedAt;

  const SearchResults({
    required this.query,
    required this.options,
    required this.results,
    required this.searchDuration,
    required this.searchedAt,
  });

  /// Total number of matches across all documents
  int get totalMatches =>
      results.fold(0, (sum, result) => sum + result.matchCount);

  /// Number of documents with matches
  int get documentCount => results.length;

  /// Check if search found any results
  bool get hasResults => results.isNotEmpty;

  /// Get all document IDs that have matches
  List<String> get matchingDocumentIds =>
      results.map((r) => r.documentId).toList();
}

/// Options for configuring search behavior
class SearchOptions {
  final bool caseSensitive;
  final bool wholeWord;
  final bool useRegex;
  final bool searchInContent;
  final bool searchInTitles;
  final bool searchInSynopsis;
  final bool searchInNotes;
  final SearchScope scope;

  const SearchOptions({
    this.caseSensitive = false,
    this.wholeWord = false,
    this.useRegex = false,
    this.searchInContent = true,
    this.searchInTitles = true,
    this.searchInSynopsis = true,
    this.searchInNotes = false,
    this.scope = SearchScope.entireProject,
  });

  SearchOptions copyWith({
    bool? caseSensitive,
    bool? wholeWord,
    bool? useRegex,
    bool? searchInContent,
    bool? searchInTitles,
    bool? searchInSynopsis,
    bool? searchInNotes,
    SearchScope? scope,
  }) {
    return SearchOptions(
      caseSensitive: caseSensitive ?? this.caseSensitive,
      wholeWord: wholeWord ?? this.wholeWord,
      useRegex: useRegex ?? this.useRegex,
      searchInContent: searchInContent ?? this.searchInContent,
      searchInTitles: searchInTitles ?? this.searchInTitles,
      searchInSynopsis: searchInSynopsis ?? this.searchInSynopsis,
      searchInNotes: searchInNotes ?? this.searchInNotes,
      scope: scope ?? this.scope,
    );
  }
}

/// Scope of the search
enum SearchScope {
  entireProject('Entire Project'),
  manuscript('Manuscript Only'),
  research('Research Only'),
  currentFolder('Current Folder'),
  selection('Selected Documents');

  final String displayName;
  const SearchScope(this.displayName);
}

/// Options for find and replace
class ReplaceOptions {
  final String replaceWith;
  final bool preserveCase;

  const ReplaceOptions({
    required this.replaceWith,
    this.preserveCase = false,
  });
}
