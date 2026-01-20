import 'search_result.dart';

/// A collection of documents that can be viewed as a filtered binder
class DocumentCollection {
  final String id;
  final String name;
  final CollectionType type;
  final List<String> documentIds;
  final SearchOptions? searchOptions; // For search-based collections
  final String? searchQuery; // For search-based collections
  final int colorValue;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isSmartCollection; // Automatically updates based on criteria

  const DocumentCollection({
    required this.id,
    required this.name,
    required this.type,
    required this.documentIds,
    this.searchOptions,
    this.searchQuery,
    this.colorValue = 0xFF2196F3, // Default blue
    required this.createdAt,
    required this.modifiedAt,
    this.isSmartCollection = false,
  });

  /// Create a new empty manual collection
  factory DocumentCollection.manual({
    required String name,
    int? colorValue,
  }) {
    final now = DateTime.now();
    return DocumentCollection(
      id: '${now.millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      type: CollectionType.manual,
      documentIds: [],
      colorValue: colorValue ?? 0xFF2196F3,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Create a collection from search results
  factory DocumentCollection.fromSearch({
    required String name,
    required String searchQuery,
    required SearchOptions searchOptions,
    required List<String> documentIds,
    bool isSmartCollection = false,
    int? colorValue,
  }) {
    final now = DateTime.now();
    return DocumentCollection(
      id: '${now.millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      type: CollectionType.search,
      documentIds: documentIds,
      searchQuery: searchQuery,
      searchOptions: searchOptions,
      colorValue: colorValue ?? 0xFF9C27B0, // Purple for search
      createdAt: now,
      modifiedAt: now,
      isSmartCollection: isSmartCollection,
    );
  }

  /// Create a "binder selection" type collection
  factory DocumentCollection.binderSelection({
    required String name,
    required List<String> documentIds,
    int? colorValue,
  }) {
    final now = DateTime.now();
    return DocumentCollection(
      id: '${now.millisecondsSinceEpoch}_${name.hashCode.abs()}',
      name: name,
      type: CollectionType.binderSelection,
      documentIds: documentIds,
      colorValue: colorValue ?? 0xFF4CAF50, // Green for selection
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Number of documents in this collection
  int get documentCount => documentIds.length;

  /// Check if collection contains a document
  bool containsDocument(String documentId) => documentIds.contains(documentId);

  /// Add a document to the collection
  DocumentCollection withAddedDocument(String documentId) {
    if (documentIds.contains(documentId)) return this;
    return copyWith(
      documentIds: [...documentIds, documentId],
      modifiedAt: DateTime.now(),
    );
  }

  /// Remove a document from the collection
  DocumentCollection withRemovedDocument(String documentId) {
    return copyWith(
      documentIds: documentIds.where((id) => id != documentId).toList(),
      modifiedAt: DateTime.now(),
    );
  }

  /// Reorder documents in the collection
  DocumentCollection withReorderedDocuments(List<String> newOrder) {
    return copyWith(
      documentIds: newOrder,
      modifiedAt: DateTime.now(),
    );
  }

  /// Update collection name
  DocumentCollection withName(String newName) {
    return copyWith(name: newName, modifiedAt: DateTime.now());
  }

  /// Update collection color
  DocumentCollection withColor(int newColorValue) {
    return copyWith(colorValue: newColorValue, modifiedAt: DateTime.now());
  }

  /// Copy with modified fields
  DocumentCollection copyWith({
    String? name,
    List<String>? documentIds,
    SearchOptions? searchOptions,
    String? searchQuery,
    int? colorValue,
    DateTime? modifiedAt,
    bool? isSmartCollection,
  }) {
    return DocumentCollection(
      id: id,
      name: name ?? this.name,
      type: type,
      documentIds: documentIds ?? this.documentIds,
      searchOptions: searchOptions ?? this.searchOptions,
      searchQuery: searchQuery ?? this.searchQuery,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isSmartCollection: isSmartCollection ?? this.isSmartCollection,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'documentIds': documentIds,
      'searchQuery': searchQuery,
      'searchOptions': searchOptions != null
          ? {
              'caseSensitive': searchOptions!.caseSensitive,
              'wholeWord': searchOptions!.wholeWord,
              'useRegex': searchOptions!.useRegex,
              'searchInContent': searchOptions!.searchInContent,
              'searchInTitles': searchOptions!.searchInTitles,
              'searchInSynopsis': searchOptions!.searchInSynopsis,
              'searchInNotes': searchOptions!.searchInNotes,
              'scope': searchOptions!.scope.name,
            }
          : null,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isSmartCollection': isSmartCollection,
    };
  }

  /// Create from JSON
  factory DocumentCollection.fromJson(Map<String, dynamic> json) {
    SearchOptions? searchOptions;
    if (json['searchOptions'] != null) {
      final opts = json['searchOptions'] as Map<String, dynamic>;
      searchOptions = SearchOptions(
        caseSensitive: opts['caseSensitive'] as bool? ?? false,
        wholeWord: opts['wholeWord'] as bool? ?? false,
        useRegex: opts['useRegex'] as bool? ?? false,
        searchInContent: opts['searchInContent'] as bool? ?? true,
        searchInTitles: opts['searchInTitles'] as bool? ?? true,
        searchInSynopsis: opts['searchInSynopsis'] as bool? ?? true,
        searchInNotes: opts['searchInNotes'] as bool? ?? false,
        scope: SearchScope.values.firstWhere(
          (s) => s.name == opts['scope'],
          orElse: () => SearchScope.entireProject,
        ),
      );
    }

    return DocumentCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      type: CollectionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CollectionType.manual,
      ),
      documentIds: (json['documentIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      searchQuery: json['searchQuery'] as String?,
      searchOptions: searchOptions,
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      isSmartCollection: json['isSmartCollection'] as bool? ?? false,
    );
  }
}

/// Types of collections
enum CollectionType {
  manual('Manual', 'Documents added manually'),
  search('Search Results', 'Based on a saved search'),
  binderSelection('Binder Selection', 'Selected from binder'),
  label('By Label', 'Documents with a specific label'),
  status('By Status', 'Documents with a specific status');

  final String displayName;
  final String description;
  const CollectionType(this.displayName, this.description);
}

/// Predefined collection colors
class CollectionColors {
  static const int blue = 0xFF2196F3;
  static const int purple = 0xFF9C27B0;
  static const int green = 0xFF4CAF50;
  static const int orange = 0xFFFF9800;
  static const int red = 0xFFF44336;
  static const int teal = 0xFF009688;
  static const int pink = 0xFFE91E63;
  static const int indigo = 0xFF3F51B5;

  static const List<int> all = [
    blue,
    purple,
    green,
    orange,
    red,
    teal,
    pink,
    indigo,
  ];
}
