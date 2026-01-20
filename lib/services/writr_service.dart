import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/scrivener_project.dart';
import '../models/document_metadata.dart';
import '../models/snapshot.dart';
import '../models/research_item.dart';
import '../utils/markdown_frontmatter.dart';

/// Generate a unique ID for new items.
String _generateUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// Service for handling native Writr projects (.writ/.writx format).
///
/// The .writ format is a folder containing:
/// - {ProjectName}.writx - JSON manifest with binder structure
/// - content/{uuid}.md - Markdown documents with YAML frontmatter
/// - research/{uuid}.{ext} - Research files (PDFs, images, etc.)
/// - research/index.json - Research metadata
/// - snapshots/{doc-uuid}/{timestamp}.md - Version snapshots
class WritrService extends ChangeNotifier {
  ScrivenerProject? _currentProject;
  bool _isLoading = false;
  String? _error;
  bool _hasUnsavedChanges = false;

  // Track which documents have been modified
  final Set<String> _dirtyDocIds = {};

  ScrivenerProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Load a Writr project from a .writ directory.
  Future<void> loadProject(String projectPath) async {
    _isLoading = true;
    _error = null;
    _dirtyDocIds.clear();
    notifyListeners();

    try {
      final projectDir = Directory(projectPath);
      if (!await projectDir.exists()) {
        throw Exception('Project directory does not exist');
      }

      // Find the .writx file
      final writxFile = await _findWritxFile(projectDir);
      if (writxFile == null) {
        throw Exception('No .writx file found in project');
      }

      // Parse the .writx JSON file
      final jsonContent = await writxFile.readAsString();
      final manifest = json.decode(jsonContent) as Map<String, dynamic>;

      // Parse binder items
      final binderItems = _parseBinderItems(manifest['binder'] as List<dynamic>?);

      // Load text contents from content/ directory
      final textContents = await _loadTextContents(projectDir, binderItems);

      // Load research items
      final researchItems = await _loadResearchItems(projectDir);

      // Load document metadata
      final documentMetadata = await _loadDocumentMetadata(projectDir);

      // Load snapshots
      final documentSnapshots = await _loadSnapshots(projectDir);

      // Create project
      final projectName = manifest['name'] as String? ??
          path.basenameWithoutExtension(writxFile.path);

      _currentProject = ScrivenerProject(
        name: projectName,
        path: projectPath,
        binderItems: binderItems,
        textContents: textContents,
        documentMetadata: documentMetadata,
        documentSnapshots: documentSnapshots,
        researchItems: researchItems,
        settings: ProjectSettings.defaults(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set a project directly (for syncing from ScrivenerService).
  void setProject(ScrivenerProject project) {
    _currentProject = project;
    _error = null;
    _hasUnsavedChanges = false;
    _dirtyDocIds.clear();
    notifyListeners();
  }

  /// Find the .writx file in the project directory.
  Future<File?> _findWritxFile(Directory projectDir) async {
    await for (final entity in projectDir.list()) {
      if (entity is File && entity.path.endsWith('.writx')) {
        return entity;
      }
    }
    return null;
  }

  /// Parse binder items from JSON.
  List<BinderItem> _parseBinderItems(List<dynamic>? items) {
    if (items == null) return [];

    return items.map((item) {
      final map = item as Map<String, dynamic>;
      return BinderItem(
        id: map['uuid'] as String? ?? _generateUniqueId(),
        title: map['title'] as String? ?? 'Untitled',
        type: _parseBinderItemType(map['type'] as String?),
        children: _parseBinderItems(map['children'] as List<dynamic>?),
        label: map['label'] as String?,
        status: map['status'] as String?,
      );
    }).toList();
  }

  /// Parse binder item type from string.
  BinderItemType _parseBinderItemType(String? type) {
    switch (type?.toLowerCase()) {
      case 'folder':
        return BinderItemType.folder;
      case 'document':
      case 'text':
        return BinderItemType.text;
      case 'image':
        return BinderItemType.image;
      case 'pdf':
        return BinderItemType.pdf;
      case 'webarchive':
        return BinderItemType.webArchive;
      default:
        return BinderItemType.text;
    }
  }

  /// Load text contents from content/ directory.
  Future<Map<String, String>> _loadTextContents(
    Directory projectDir,
    List<BinderItem> binderItems,
  ) async {
    final textContents = <String, String>{};
    final contentDir = Directory(path.join(projectDir.path, 'content'));

    if (!await contentDir.exists()) {
      return textContents;
    }

    // Collect all document IDs from binder
    final docIds = <String>{};
    void collectIds(List<BinderItem> items) {
      for (final item in items) {
        if (item.type == BinderItemType.text) {
          docIds.add(item.id);
        }
        collectIds(item.children);
      }
    }
    collectIds(binderItems);

    // Load each markdown file
    for (final docId in docIds) {
      final mdFile = File(path.join(contentDir.path, '$docId.md'));
      if (await mdFile.exists()) {
        try {
          final content = await mdFile.readAsString();
          final parsed = parseMarkdownWithFrontmatter(content);
          textContents[docId] = parsed.content;
        } catch (e) {
          debugPrint('Error loading document $docId: $e');
        }
      }
    }

    return textContents;
  }

  /// Load research items from research/ directory.
  Future<Map<String, ResearchItem>> _loadResearchItems(Directory projectDir) async {
    final researchDir = Directory(path.join(projectDir.path, 'research'));
    final indexFile = File(path.join(researchDir.path, 'index.json'));

    if (!await indexFile.exists()) {
      return {};
    }

    try {
      final content = await indexFile.readAsString();
      final index = json.decode(content) as Map<String, dynamic>;
      final items = <String, ResearchItem>{};

      for (final entry in index.entries) {
        final data = entry.value as Map<String, dynamic>;
        final filePath = path.join(researchDir.path, data['file'] as String? ?? '');

        items[entry.key] = ResearchItem(
          id: entry.key,
          title: data['title'] as String? ?? 'Untitled',
          type: ResearchItemType.fromExtension(path.extension(filePath)),
          filePath: filePath,
          mimeType: data['mimeType'] as String?,
          fileSize: data['fileSize'] as int?,
          createdAt: data['created'] != null
              ? DateTime.parse(data['created'] as String)
              : DateTime.now(),
          modifiedAt: data['modified'] != null
              ? DateTime.parse(data['modified'] as String)
              : DateTime.now(),
          description: data['description'] as String?,
          linkedDocumentIds: (data['linkedDocuments'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
        );
      }

      return items;
    } catch (e) {
      debugPrint('Error loading research index: $e');
      return {};
    }
  }

  /// Load document metadata from metadata/documents.json.
  Future<Map<String, DocumentMetadata>> _loadDocumentMetadata(
    Directory projectDir,
  ) async {
    final metadataFile = File(
      path.join(projectDir.path, 'metadata', 'documents.json'),
    );

    if (!await metadataFile.exists()) {
      return {};
    }

    try {
      final content = await metadataFile.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      final metadata = <String, DocumentMetadata>{};

      for (final entry in data.entries) {
        final docData = entry.value as Map<String, dynamic>;
        metadata[entry.key] = DocumentMetadata(
          documentId: entry.key,
          status: _parseDocumentStatus(docData['status'] as String?),
          synopsis: docData['synopsis'] as String? ?? '',
          notes: docData['notes'] as String? ?? '',
          wordCountTarget: docData['wordCountTarget'] as int?,
          includeInCompile: docData['includeInCompile'] as bool? ?? true,
          customIcon: docData['customIcon'] as String?,
          createdAt: docData['createdAt'] != null
              ? DateTime.parse(docData['createdAt'] as String)
              : DateTime.now(),
          modifiedAt: docData['modifiedAt'] != null
              ? DateTime.parse(docData['modifiedAt'] as String)
              : DateTime.now(),
        );
      }

      return metadata;
    } catch (e) {
      debugPrint('Error loading document metadata: $e');
      return {};
    }
  }

  DocumentStatus _parseDocumentStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'todo':
        return DocumentStatus.toDo;
      case 'inprogress':
        return DocumentStatus.inProgress;
      case 'firstdraft':
        return DocumentStatus.firstDraft;
      case 'reviseddraft':
        return DocumentStatus.revisedDraft;
      case 'finaldraft':
        return DocumentStatus.finalDraft;
      case 'done':
        return DocumentStatus.done;
      default:
        return DocumentStatus.noStatus;
    }
  }

  /// Load snapshots from snapshots/ directory.
  Future<Map<String, List<DocumentSnapshot>>> _loadSnapshots(
    Directory projectDir,
  ) async {
    final snapshotsDir = Directory(path.join(projectDir.path, 'snapshots'));
    final snapshots = <String, List<DocumentSnapshot>>{};

    if (!await snapshotsDir.exists()) {
      return snapshots;
    }

    await for (final entity in snapshotsDir.list()) {
      if (entity is Directory) {
        final docId = path.basename(entity.path);
        final docSnapshots = <DocumentSnapshot>[];

        await for (final file in entity.list()) {
          if (file is File && file.path.endsWith('.md')) {
            try {
              final content = await file.readAsString();
              final parsed = parseMarkdownWithFrontmatter(content);
              final timestamp = path.basenameWithoutExtension(file.path);

              docSnapshots.add(DocumentSnapshot(
                id: timestamp,
                documentId: docId,
                title: parsed.getString('title') ?? 'Snapshot',
                content: parsed.content,
                createdAt: DateTime.tryParse(timestamp) ?? DateTime.now(),
                note: parsed.getString('note'),
              ));
            } catch (e) {
              debugPrint('Error loading snapshot: $e');
            }
          }
        }

        // Sort by creation date, newest first
        docSnapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (docSnapshots.isNotEmpty) {
          snapshots[docId] = docSnapshots;
        }
      }
    }

    return snapshots;
  }

  /// Save the current project.
  Future<void> saveProject() async {
    if (_currentProject == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final projectDir = Directory(_currentProject!.path);

      // Save .writx manifest
      await _saveWritxManifest(projectDir);

      // Save text contents to content/ directory
      await _saveTextContents(projectDir);

      // Save research items
      await _saveResearchItems(projectDir);

      // Save document metadata
      await _saveDocumentMetadata(projectDir);

      // Save snapshots
      await _saveSnapshots(projectDir);

      _dirtyDocIds.clear();
      _hasUnsavedChanges = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save the .writx manifest file.
  Future<void> _saveWritxManifest(Directory projectDir) async {
    final manifest = {
      'format': 'writx',
      'version': '1.0',
      'name': _currentProject!.name,
      'uuid': _generateUniqueId(), // TODO: persist project UUID
      'created': DateTime.now().toIso8601String(),
      'modified': DateTime.now().toIso8601String(),
      'binder': _binderItemsToJson(_currentProject!.binderItems),
      'labels': _currentProject!.labels.toJson(),
      'statuses': _currentProject!.statuses.toJson(),
    };

    final writxFile = File(
      path.join(projectDir.path, '${_currentProject!.name}.writx'),
    );
    await writxFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
  }

  List<Map<String, dynamic>> _binderItemsToJson(List<BinderItem> items) {
    return items.map((item) {
      return {
        'uuid': item.id,
        'type': _binderItemTypeToString(item.type),
        'title': item.title,
        if (item.label != null) 'label': item.label,
        if (item.status != null) 'status': item.status,
        if (item.children.isNotEmpty) 'children': _binderItemsToJson(item.children),
      };
    }).toList();
  }

  String _binderItemTypeToString(BinderItemType type) {
    switch (type) {
      case BinderItemType.folder:
        return 'folder';
      case BinderItemType.text:
        return 'document';
      case BinderItemType.image:
        return 'image';
      case BinderItemType.pdf:
        return 'pdf';
      case BinderItemType.webArchive:
        return 'webArchive';
    }
  }

  /// Save text contents as Markdown files.
  Future<void> _saveTextContents(Directory projectDir) async {
    final contentDir = Directory(path.join(projectDir.path, 'content'));
    await contentDir.create(recursive: true);

    for (final entry in _currentProject!.textContents.entries) {
      final docId = entry.key;
      final content = entry.value;

      // Get metadata for frontmatter
      final metadata = _currentProject!.documentMetadata[docId];
      final binderItem = _findBinderItem(_currentProject!.binderItems, docId);

      final frontmatter = <String, dynamic>{
        'title': binderItem?.title ?? 'Untitled',
      };

      if (metadata != null) {
        if (metadata.synopsis.isNotEmpty) {
          frontmatter['synopsis'] = metadata.synopsis;
        }
        if (metadata.wordCountTarget != null) {
          frontmatter['wordTarget'] = metadata.wordCountTarget;
        }
        frontmatter['includeInCompile'] = metadata.includeInCompile;
      }

      final mdContent = writeMarkdownWithFrontmatter(
        frontmatter: frontmatter,
        content: content,
      );

      final mdFile = File(path.join(contentDir.path, '$docId.md'));
      await mdFile.writeAsString(mdContent);
    }
  }

  BinderItem? _findBinderItem(List<BinderItem> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
      final found = _findBinderItem(item.children, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Save research items and index.
  Future<void> _saveResearchItems(Directory projectDir) async {
    if (_currentProject!.researchItems.isEmpty) return;

    final researchDir = Directory(path.join(projectDir.path, 'research'));
    await researchDir.create(recursive: true);

    final index = <String, dynamic>{};

    for (final entry in _currentProject!.researchItems.entries) {
      final item = entry.value;
      final fileName = '${item.id}.${item.fileExtension}';

      index[item.id] = {
        'title': item.title,
        'file': fileName,
        'mimeType': item.mimeType,
        'fileSize': item.fileSize,
        'created': item.createdAt.toIso8601String(),
        'modified': item.modifiedAt.toIso8601String(),
        if (item.description != null) 'description': item.description,
        if (item.linkedDocumentIds.isNotEmpty)
          'linkedDocuments': item.linkedDocumentIds,
      };

      // Write file data if available
      if (item.data != null) {
        final file = File(path.join(researchDir.path, fileName));
        await file.writeAsBytes(item.data!);
      }
    }

    final indexFile = File(path.join(researchDir.path, 'index.json'));
    await indexFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(index),
    );
  }

  /// Save document metadata.
  Future<void> _saveDocumentMetadata(Directory projectDir) async {
    if (_currentProject!.documentMetadata.isEmpty) return;

    final metadataDir = Directory(path.join(projectDir.path, 'metadata'));
    await metadataDir.create(recursive: true);

    final data = <String, dynamic>{};

    for (final entry in _currentProject!.documentMetadata.entries) {
      final meta = entry.value;
      data[entry.key] = {
        'status': meta.status.name,
        'synopsis': meta.synopsis,
        'notes': meta.notes,
        if (meta.wordCountTarget != null) 'wordCountTarget': meta.wordCountTarget,
        'includeInCompile': meta.includeInCompile,
        if (meta.customIcon != null) 'customIcon': meta.customIcon,
        'createdAt': meta.createdAt.toIso8601String(),
        'modifiedAt': meta.modifiedAt.toIso8601String(),
      };
    }

    final metadataFile = File(path.join(metadataDir.path, 'documents.json'));
    await metadataFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  /// Save snapshots.
  Future<void> _saveSnapshots(Directory projectDir) async {
    if (_currentProject!.documentSnapshots.isEmpty) return;

    final snapshotsDir = Directory(path.join(projectDir.path, 'snapshots'));

    for (final entry in _currentProject!.documentSnapshots.entries) {
      final docId = entry.key;
      final docSnapshots = entry.value;

      if (docSnapshots.isEmpty) continue;

      final docSnapshotDir = Directory(path.join(snapshotsDir.path, docId));
      await docSnapshotDir.create(recursive: true);

      for (final snapshot in docSnapshots) {
        final frontmatter = <String, dynamic>{
          'title': snapshot.title,
          if (snapshot.note != null) 'note': snapshot.note,
        };

        final mdContent = writeMarkdownWithFrontmatter(
          frontmatter: frontmatter,
          content: snapshot.content,
        );

        final timestamp = snapshot.createdAt.toIso8601String().replaceAll(':', '-');
        final snapshotFile = File(path.join(docSnapshotDir.path, '$timestamp.md'));
        await snapshotFile.writeAsString(mdContent);
      }
    }
  }

  /// Create a new Writr project.
  Future<void> createProject(String name, String directory) async {
    _isLoading = true;
    notifyListeners();

    try {
      final projectPath = path.join(directory, '$name.writ');
      final projectDir = Directory(projectPath);

      // Create project directory structure
      await projectDir.create(recursive: true);
      await Directory(path.join(projectPath, 'content')).create(recursive: true);
      await Directory(path.join(projectPath, 'research')).create(recursive: true);
      await Directory(path.join(projectPath, 'snapshots')).create(recursive: true);
      await Directory(path.join(projectPath, 'metadata')).create(recursive: true);

      // Create empty project with default structure
      _currentProject = ScrivenerProject.empty(name, projectPath);

      // Save initial project structure
      await saveProject();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update text content for a document.
  void updateTextContent(String itemId, String content) {
    if (_currentProject == null) return;

    final updatedContents = Map<String, String>.from(_currentProject!.textContents);
    updatedContents[itemId] = content;

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: _currentProject!.binderItems,
      textContents: updatedContents,
      documentMetadata: _currentProject!.documentMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: _currentProject!.researchItems,
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );
    _dirtyDocIds.add(itemId);
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Add a new binder item.
  void addBinderItem({
    required String title,
    required BinderItemType type,
    String? parentId,
  }) {
    if (_currentProject == null) return;

    final newItem = BinderItem(
      id: _generateUniqueId(),
      title: title,
      type: type,
      children: [],
    );

    List<BinderItem> updatedItems;
    if (parentId == null) {
      updatedItems = [..._currentProject!.binderItems, newItem];
    } else {
      updatedItems = _addItemToParent(
        _currentProject!.binderItems,
        parentId,
        newItem,
      );
    }

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: updatedItems,
      textContents: _currentProject!.textContents,
      documentMetadata: _currentProject!.documentMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: _currentProject!.researchItems,
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  List<BinderItem> _addItemToParent(
    List<BinderItem> items,
    String parentId,
    BinderItem newItem,
  ) {
    return items.map((item) {
      if (item.id == parentId) {
        return item.copyWith(children: [...item.children, newItem]);
      } else if (item.children.isNotEmpty) {
        return item.copyWith(
          children: _addItemToParent(item.children, parentId, newItem),
        );
      }
      return item;
    }).toList();
  }

  /// Delete a binder item.
  void deleteBinderItem(String itemId) {
    if (_currentProject == null) return;

    final updatedItems = _deleteItemRecursive(_currentProject!.binderItems, itemId);
    final updatedContents = Map<String, String>.from(_currentProject!.textContents);
    updatedContents.remove(itemId);

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: updatedItems,
      textContents: updatedContents,
      documentMetadata: _currentProject!.documentMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: _currentProject!.researchItems,
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  List<BinderItem> _deleteItemRecursive(List<BinderItem> items, String itemId) {
    return items
        .where((item) => item.id != itemId)
        .map((item) {
          if (item.children.isNotEmpty) {
            return item.copyWith(
              children: _deleteItemRecursive(item.children, itemId),
            );
          }
          return item;
        })
        .toList();
  }

  /// Rename a binder item.
  void renameBinderItem(String itemId, String newTitle) {
    if (_currentProject == null) return;

    final updatedItems = _renameItemRecursive(
      _currentProject!.binderItems,
      itemId,
      newTitle,
    );

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: updatedItems,
      textContents: _currentProject!.textContents,
      documentMetadata: _currentProject!.documentMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: _currentProject!.researchItems,
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  List<BinderItem> _renameItemRecursive(
    List<BinderItem> items,
    String itemId,
    String newTitle,
  ) {
    return items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(title: newTitle);
      } else if (item.children.isNotEmpty) {
        return item.copyWith(
          children: _renameItemRecursive(item.children, itemId, newTitle),
        );
      }
      return item;
    }).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
