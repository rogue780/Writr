import 'package:flutter/foundation.dart';
import '../models/collection.dart';
import '../models/scrivener_project.dart';
import '../models/search_result.dart';
import 'search_service.dart';

/// Service for managing document collections
class CollectionService extends ChangeNotifier {
  final Map<String, DocumentCollection> _collections = {};
  String? _activeCollectionId;
  final SearchService _searchService;

  CollectionService({SearchService? searchService})
      : _searchService = searchService ?? SearchService();

  /// Get all collections
  List<DocumentCollection> get collections => _collections.values.toList();

  /// Get the currently active collection
  DocumentCollection? get activeCollection =>
      _activeCollectionId != null ? _collections[_activeCollectionId] : null;

  /// Get a collection by ID
  DocumentCollection? getCollection(String id) => _collections[id];

  /// Set the active collection
  void setActiveCollection(String? collectionId) {
    _activeCollectionId = collectionId;
    notifyListeners();
  }

  /// Create a new manual collection
  DocumentCollection createManualCollection(String name, {int? colorValue}) {
    final collection = DocumentCollection.manual(
      name: name,
      colorValue: colorValue,
    );
    _collections[collection.id] = collection;
    notifyListeners();
    return collection;
  }

  /// Create a collection from search results
  DocumentCollection createSearchCollection({
    required String name,
    required String searchQuery,
    required SearchOptions searchOptions,
    required List<String> documentIds,
    bool isSmartCollection = false,
    int? colorValue,
  }) {
    final collection = DocumentCollection.fromSearch(
      name: name,
      searchQuery: searchQuery,
      searchOptions: searchOptions,
      documentIds: documentIds,
      isSmartCollection: isSmartCollection,
      colorValue: colorValue,
    );
    _collections[collection.id] = collection;
    notifyListeners();
    return collection;
  }

  /// Create a collection from current binder selection
  DocumentCollection createFromSelection({
    required String name,
    required List<String> documentIds,
    int? colorValue,
  }) {
    final collection = DocumentCollection.binderSelection(
      name: name,
      documentIds: documentIds,
      colorValue: colorValue,
    );
    _collections[collection.id] = collection;
    notifyListeners();
    return collection;
  }

  /// Update a collection
  void updateCollection(DocumentCollection collection) {
    _collections[collection.id] = collection;
    notifyListeners();
  }

  /// Delete a collection
  void deleteCollection(String collectionId) {
    _collections.remove(collectionId);
    if (_activeCollectionId == collectionId) {
      _activeCollectionId = null;
    }
    notifyListeners();
  }

  /// Add a document to a collection
  void addDocumentToCollection(String collectionId, String documentId) {
    final collection = _collections[collectionId];
    if (collection != null) {
      _collections[collectionId] = collection.withAddedDocument(documentId);
      notifyListeners();
    }
  }

  /// Remove a document from a collection
  void removeDocumentFromCollection(String collectionId, String documentId) {
    final collection = _collections[collectionId];
    if (collection != null) {
      _collections[collectionId] = collection.withRemovedDocument(documentId);
      notifyListeners();
    }
  }

  /// Reorder documents in a collection
  void reorderDocuments(String collectionId, List<String> newOrder) {
    final collection = _collections[collectionId];
    if (collection != null) {
      _collections[collectionId] = collection.withReorderedDocuments(newOrder);
      notifyListeners();
    }
  }

  /// Rename a collection
  void renameCollection(String collectionId, String newName) {
    final collection = _collections[collectionId];
    if (collection != null) {
      _collections[collectionId] = collection.withName(newName);
      notifyListeners();
    }
  }

  /// Change collection color
  void setCollectionColor(String collectionId, int colorValue) {
    final collection = _collections[collectionId];
    if (collection != null) {
      _collections[collectionId] = collection.withColor(colorValue);
      notifyListeners();
    }
  }

  /// Refresh a smart collection (re-run its search)
  Future<void> refreshSmartCollection(
    String collectionId,
    ScrivenerProject project,
  ) async {
    final collection = _collections[collectionId];
    if (collection == null ||
        !collection.isSmartCollection ||
        collection.searchQuery == null ||
        collection.searchOptions == null) {
      return;
    }

    final results = await _searchService.search(
      project,
      collection.searchQuery!,
      options: collection.searchOptions!,
    );

    _collections[collectionId] = collection.copyWith(
      documentIds: results.matchingDocumentIds,
      modifiedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Refresh all smart collections
  Future<void> refreshAllSmartCollections(ScrivenerProject project) async {
    for (final collection in _collections.values) {
      if (collection.isSmartCollection) {
        await refreshSmartCollection(collection.id, project);
      }
    }
  }

  /// Get documents in a collection, preserving order
  List<BinderItem> getCollectionDocuments(
    String collectionId,
    ScrivenerProject project,
  ) {
    final collection = _collections[collectionId];
    if (collection == null) return [];

    final documents = <BinderItem>[];
    for (final docId in collection.documentIds) {
      final item = _findBinderItem(project.binderItems, docId);
      if (item != null) {
        documents.add(item);
      }
    }
    return documents;
  }

  /// Find a binder item by ID
  BinderItem? _findBinderItem(List<BinderItem> items, String itemId) {
    for (final item in items) {
      if (item.id == itemId) return item;
      if (item.children.isNotEmpty) {
        final found = _findBinderItem(item.children, itemId);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Check if a document is in any collection
  List<DocumentCollection> getCollectionsContaining(String documentId) {
    return _collections.values
        .where((c) => c.containsDocument(documentId))
        .toList();
  }

  /// Load collections from JSON
  void loadFromJson(List<Map<String, dynamic>> jsonList) {
    _collections.clear();
    for (final json in jsonList) {
      try {
        final collection = DocumentCollection.fromJson(json);
        _collections[collection.id] = collection;
      } catch (e) {
        debugPrint('Error loading collection: $e');
      }
    }
    notifyListeners();
  }

  /// Save collections to JSON
  List<Map<String, dynamic>> toJson() {
    return _collections.values.map((c) => c.toJson()).toList();
  }

  /// Clear all collections
  void clear() {
    _collections.clear();
    _activeCollectionId = null;
    notifyListeners();
  }
}
