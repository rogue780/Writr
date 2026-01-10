import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;
import '../models/scrivener_project.dart';

class ScrivenerService extends ChangeNotifier {
  ScrivenerProject? _currentProject;
  bool _isLoading = false;
  String? _error;

  ScrivenerProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load a Scrivener project from a .scriv directory
  Future<void> loadProject(String projectPath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final projectDir = Directory(projectPath);
      if (!await projectDir.exists()) {
        throw Exception('Project directory does not exist');
      }

      // Find the .scrivx file
      final scrivxFile = await _findScrivxFile(projectDir);
      if (scrivxFile == null) {
        throw Exception('No .scrivx file found in project');
      }

      // Parse the .scrivx XML file
      final xmlContent = await scrivxFile.readAsString();
      final document = XmlDocument.parse(xmlContent);

      // Parse binder items
      final binderItems = _parseBinderItems(document);

      // Load text contents from Files/Data directory
      final textContents = await _loadTextContents(projectDir);

      // Create project
      final projectName = path.basenameWithoutExtension(scrivxFile.path);
      _currentProject = ScrivenerProject(
        name: projectName,
        path: projectPath,
        binderItems: binderItems,
        textContents: textContents,
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

  /// Find the .scrivx file in the project directory
  Future<File?> _findScrivxFile(Directory projectDir) async {
    await for (final entity in projectDir.list()) {
      if (entity is File && entity.path.endsWith('.scrivx')) {
        return entity;
      }
    }
    return null;
  }

  /// Parse binder items from XML
  List<BinderItem> _parseBinderItems(XmlDocument document) {
    final binderElement = document.findAllElements('Binder').firstOrNull;
    if (binderElement == null) return [];

    final items = <BinderItem>[];
    for (final child in binderElement.children.whereType<XmlElement>()) {
      if (child.name.local == 'BinderItem') {
        final item = _parseBinderItem(child);
        if (item != null) items.add(item);
      }
    }
    return items;
  }

  /// Parse a single binder item recursively
  BinderItem? _parseBinderItem(XmlElement element) {
    final id = element.getAttribute('ID') ?? '';
    final type = element.getAttribute('Type') ?? 'Text';
    final title = element.findElements('Title').firstOrNull?.innerText ?? 'Untitled';

    // Parse children
    final children = <BinderItem>[];
    final childrenElement = element.findElements('Children').firstOrNull;
    if (childrenElement != null) {
      for (final child in childrenElement.children.whereType<XmlElement>()) {
        if (child.name.local == 'BinderItem') {
          final childItem = _parseBinderItem(child);
          if (childItem != null) children.add(childItem);
        }
      }
    }

    return BinderItem(
      id: id,
      title: title,
      type: _parseBinderItemType(type),
      children: children,
    );
  }

  /// Parse binder item type from string
  BinderItemType _parseBinderItemType(String type) {
    switch (type.toLowerCase()) {
      case 'folder':
        return BinderItemType.folder;
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

  /// Load text contents from Files/Data directory
  Future<Map<String, String>> _loadTextContents(Directory projectDir) async {
    final textContents = <String, String>{};
    final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data'));

    if (!await dataDir.exists()) {
      return textContents;
    }

    await for (final entity in dataDir.list(recursive: true)) {
      if (entity is File) {
        try {
          final fileId = path.basenameWithoutExtension(entity.path);
          final content = await entity.readAsString();
          textContents[fileId] = content;
        } catch (e) {
          // Skip files that can't be read
          debugPrint('Error reading file ${entity.path}: $e');
        }
      }
    }

    return textContents;
  }

  /// Save the current project
  Future<void> saveProject() async {
    if (_currentProject == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final projectDir = Directory(_currentProject!.path);

      // Save text contents to Files/Data directory
      await _saveTextContents(projectDir, _currentProject!.textContents);

      // Generate and save .scrivx XML file
      await _saveScrivxFile(projectDir, _currentProject!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save text contents to Files/Data directory
  Future<void> _saveTextContents(
    Directory projectDir,
    Map<String, String> textContents,
  ) async {
    final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data'));
    await dataDir.create(recursive: true);

    for (final entry in textContents.entries) {
      final file = File(path.join(dataDir.path, '${entry.key}.rtf'));
      await file.writeAsString(entry.value);
    }
  }

  /// Save .scrivx XML file
  Future<void> _saveScrivxFile(
    Directory projectDir,
    ScrivenerProject project,
  ) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('ScrivenerProject', nest: () {
      builder.attribute('Identifier', project.name);
      builder.attribute('Version', '3.0');

      // Binder section
      builder.element('Binder', nest: () {
        for (final item in project.binderItems) {
          _buildBinderItemXml(builder, item);
        }
      });
    });

    final xmlDocument = builder.buildDocument();
    final xmlString = xmlDocument.toXmlString(pretty: true, indent: '  ');

    final scrivxFile =
        File(path.join(projectDir.path, '${project.name}.scrivx'));
    await scrivxFile.writeAsString(xmlString);
  }

  /// Build XML for a binder item recursively
  void _buildBinderItemXml(XmlBuilder builder, BinderItem item) {
    builder.element('BinderItem', nest: () {
      builder.attribute('ID', item.id);
      builder.attribute('Type', _binderItemTypeToString(item.type));

      builder.element('Title', nest: item.title);

      if (item.children.isNotEmpty) {
        builder.element('Children', nest: () {
          for (final child in item.children) {
            _buildBinderItemXml(builder, child);
          }
        });
      }
    });
  }

  /// Convert binder item type to string
  String _binderItemTypeToString(BinderItemType type) {
    switch (type) {
      case BinderItemType.folder:
        return 'Folder';
      case BinderItemType.text:
        return 'Text';
      case BinderItemType.image:
        return 'Image';
      case BinderItemType.pdf:
        return 'PDF';
      case BinderItemType.webArchive:
        return 'WebArchive';
    }
  }

  /// Create a new project
  Future<void> createProject(String name, String directory) async {
    _isLoading = true;
    notifyListeners();

    try {
      final projectPath = path.join(directory, '$name.scriv');
      final projectDir = Directory(projectPath);

      // Create project directory structure
      await projectDir.create(recursive: true);
      await Directory(path.join(projectPath, 'Files', 'Data'))
          .create(recursive: true);
      await Directory(path.join(projectPath, 'Files', 'Docs'))
          .create(recursive: true);
      await Directory(path.join(projectPath, 'Settings'))
          .create(recursive: true);

      // Create empty project
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

  /// Update text content for a binder item
  void updateTextContent(String itemId, String content) {
    if (_currentProject == null) return;

    final updatedContents =
        Map<String, String>.from(_currentProject!.textContents);
    updatedContents[itemId] = content;

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: _currentProject!.binderItems,
      textContents: updatedContents,
      settings: _currentProject!.settings,
    );

    notifyListeners();
  }

  /// Add a new binder item (folder or document)
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
      // Add to root level
      updatedItems = [..._currentProject!.binderItems, newItem];
    } else {
      // Add as child of parent
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
      settings: _currentProject!.settings,
    );

    notifyListeners();
  }

  /// Rename a binder item
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
      settings: _currentProject!.settings,
    );

    notifyListeners();
  }

  /// Delete a binder item
  void deleteBinderItem(String itemId) {
    if (_currentProject == null) return;

    final updatedItems = _deleteItemRecursive(
      _currentProject!.binderItems,
      itemId,
    );

    // Also remove text content for this item
    final updatedContents =
        Map<String, String>.from(_currentProject!.textContents);
    updatedContents.remove(itemId);

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: updatedItems,
      textContents: updatedContents,
      settings: _currentProject!.settings,
    );

    notifyListeners();
  }

  /// Generate a unique ID for new items
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Add item as child of parent (recursive)
  List<BinderItem> _addItemToParent(
    List<BinderItem> items,
    String parentId,
    BinderItem newItem,
  ) {
    return items.map((item) {
      if (item.id == parentId) {
        return BinderItem(
          id: item.id,
          title: item.title,
          type: item.type,
          children: [...item.children, newItem],
          label: item.label,
          status: item.status,
          textContent: item.textContent,
        );
      } else if (item.children.isNotEmpty) {
        return BinderItem(
          id: item.id,
          title: item.title,
          type: item.type,
          children: _addItemToParent(item.children, parentId, newItem),
          label: item.label,
          status: item.status,
          textContent: item.textContent,
        );
      }
      return item;
    }).toList();
  }

  /// Rename item recursively
  List<BinderItem> _renameItemRecursive(
    List<BinderItem> items,
    String itemId,
    String newTitle,
  ) {
    return items.map((item) {
      if (item.id == itemId) {
        return BinderItem(
          id: item.id,
          title: newTitle,
          type: item.type,
          children: item.children,
          label: item.label,
          status: item.status,
          textContent: item.textContent,
        );
      } else if (item.children.isNotEmpty) {
        return BinderItem(
          id: item.id,
          title: item.title,
          type: item.type,
          children: _renameItemRecursive(item.children, itemId, newTitle),
          label: item.label,
          status: item.status,
          textContent: item.textContent,
        );
      }
      return item;
    }).toList();
  }

  /// Delete item recursively
  List<BinderItem> _deleteItemRecursive(
    List<BinderItem> items,
    String itemId,
  ) {
    return items
        .where((item) => item.id != itemId)
        .map((item) {
          if (item.children.isNotEmpty) {
            return BinderItem(
              id: item.id,
              title: item.title,
              type: item.type,
              children: _deleteItemRecursive(item.children, itemId),
              label: item.label,
              status: item.status,
              textContent: item.textContent,
            );
          }
          return item;
        })
        .toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
