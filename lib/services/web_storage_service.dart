import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/scrivener_project.dart';
import '../models/research_item.dart';
import '../utils/rtf_parser.dart';

/// Service for storing Scrivener projects in browser storage (web platform)
class WebStorageService extends ChangeNotifier {
  static const String _projectsKey = 'web_projects';
  static const String _currentProjectKey = 'current_project_id';

  Map<String, Map<String, dynamic>> _projects = {};
  String? _currentProjectId;
  bool _isLoaded = false;

  Map<String, Map<String, dynamic>> get projects => _projects;
  String? get currentProjectId => _currentProjectId;
  bool get isLoaded => _isLoaded;

  /// Load all projects from browser storage
  Future<void> loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_projectsKey);
      _currentProjectId = prefs.getString(_currentProjectKey);

      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        _projects = decoded.map(
          (key, value) => MapEntry(key, value as Map<String, dynamic>),
        );
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading web projects: $e');
      _projects = {};
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Save a project to browser storage
  Future<void> saveProject(ScrivenerProject project) async {
    try {
      // Convert project to JSON
      final projectJson = _projectToJson(project);

      // Store in projects map
      _projects[project.path] = projectJson;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      try {
        final jsonString = json.encode(_projects);
        await prefs.setString(_projectsKey, jsonString);
      } catch (e) {
        print('Error encoding project to JSON: $e');
        print('Project path: ${project.path}');
        print('Project name: ${project.name}');
        print('Binder items count: ${project.binderItems.length}');
        rethrow;
      }

      notifyListeners();
    } catch (e) {
      print('Error saving web project: $e');
      rethrow;
    }
  }

  /// Load a project from browser storage
  Future<ScrivenerProject?> loadProject(String projectPath) async {
    try {
      if (!_projects.containsKey(projectPath)) {
        return null;
      }

      final projectJson = _projects[projectPath]!;
      return _projectFromJson(projectJson);
    } catch (e) {
      print('Error loading web project: $e');
      return null;
    }
  }

  /// Delete a project from browser storage
  Future<void> deleteProject(String projectPath) async {
    try {
      _projects.remove(projectPath);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_projects);
      await prefs.setString(_projectsKey, jsonString);

      if (_currentProjectId == projectPath) {
        _currentProjectId = null;
        await prefs.remove(_currentProjectKey);
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting web project: $e');
      rethrow;
    }
  }

  /// Set the current project
  Future<void> setCurrentProject(String projectPath) async {
    try {
      _currentProjectId = projectPath;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentProjectKey, projectPath);

      notifyListeners();
    } catch (e) {
      print('Error setting current project: $e');
    }
  }

  /// Get list of all project names
  List<String> getProjectNames() {
    return _projects.keys.toList();
  }

  /// Convert ScrivenerProject to JSON
  Map<String, dynamic> _projectToJson(ScrivenerProject project) {
    return {
      'name': project.name,
      'path': project.path,
      'binderItems': project.binderItems.map((item) => _binderItemToJson(item)).toList(),
      'textContents': project.textContents,
      'settings': {
        'autoSave': project.settings.autoSave,
        'autoSaveInterval': project.settings.autoSaveInterval,
        'defaultTextFormat': project.settings.defaultTextFormat,
      },
    };
  }

  /// Convert JSON to ScrivenerProject
  ScrivenerProject _projectFromJson(Map<String, dynamic> json) {
    return ScrivenerProject(
      name: json['name'],
      path: json['path'],
      binderItems: (json['binderItems'] as List)
          .map((item) => _binderItemFromJson(item))
          .toList(),
      textContents: Map<String, String>.from(json['textContents']),
      settings: ProjectSettings(
        autoSave: json['settings']['autoSave'],
        autoSaveInterval: json['settings']['autoSaveInterval'],
        defaultTextFormat: json['settings']['defaultTextFormat'],
      ),
    );
  }

  /// Convert BinderItem to JSON
  Map<String, dynamic> _binderItemToJson(BinderItem item) {
    return {
      'id': item.id.toString(),
      'title': item.title.toString(),
      'type': item.type.toString(),
      'children': item.children.map((child) => _binderItemToJson(child)).toList(),
      if (item.label != null) 'label': item.label.toString(),
      if (item.status != null) 'status': item.status.toString(),
    };
  }

  /// Convert JSON to BinderItem
  BinderItem _binderItemFromJson(Map<String, dynamic> json) {
    return BinderItem(
      id: json['id'].toString(),
      title: json['title'].toString(),
      type: _parseBinderItemType(json['type'].toString()),
      children: (json['children'] as List)
          .map((child) => _binderItemFromJson(child))
          .toList(),
      label: json['label']?.toString(),
      status: json['status']?.toString(),
    );
  }

  /// Parse BinderItemType from string
  BinderItemType _parseBinderItemType(String typeString) {
    switch (typeString) {
      case 'BinderItemType.folder':
        return BinderItemType.folder;
      case 'BinderItemType.text':
        return BinderItemType.text;
      case 'BinderItemType.image':
        return BinderItemType.image;
      case 'BinderItemType.pdf':
        return BinderItemType.pdf;
      case 'BinderItemType.webArchive':
        return BinderItemType.webArchive;
      default:
        return BinderItemType.text;
    }
  }

  /// Export a project as a .scriv zip file
  /// Returns the zip file bytes ready for download
  Uint8List exportProject(ScrivenerProject project) {
    final archive = Archive();

    // Create .scrivx XML file
    final scrivxContent = _createScrivxXml(project);
    archive.addFile(ArchiveFile(
      '${project.name}.scrivx',
      scrivxContent.length,
      scrivxContent,
    ));

    // Create Files/Data directory with text content files
    for (final entry in project.textContents.entries) {
      final content = utf8.encode(entry.value);
      archive.addFile(ArchiveFile(
        'Files/Data/${entry.key}.rtf',
        content.length,
        content,
      ));
    }

    // Add research items (PDFs/images/etc.) when available.
    for (final item in project.researchItems.values) {
      if (item.data == null || item.data!.isEmpty) {
        continue;
      }

      final fileName = '${item.id}.${item.fileExtension}';
      archive.addFile(ArchiveFile(
        'Files/Docs/$fileName',
        item.data!.length,
        item.data!,
      ));
    }

    // Encode as zip
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    return Uint8List.fromList(zipBytes!);
  }

  /// Import a .scriv zip file and save to browser storage
  Future<ScrivenerProject?> importProject(Uint8List zipBytes, String projectName) async {
    try {
      // Decode zip
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Find and parse .scrivx file
      final scrivxFile = archive.files.firstWhere(
        (file) => file.name.endsWith('.scrivx'),
      );
      final scrivxContent = utf8.decode(scrivxFile.content as List<int>);
      final document = XmlDocument.parse(scrivxContent);

      // Parse binder items
      final binderItems = _parseBinderItemsFromXml(document);

      // Load text contents from Files/Data
      final textContents = <String, String>{};
      final binderTitleById = <String, String>{};
      void collectTitles(List<BinderItem> items) {
        for (final item in items) {
          binderTitleById[item.id] = item.title;
          if (item.children.isNotEmpty) {
            collectTitles(item.children);
          }
        }
      }
      collectTitles(binderItems);

      for (final file in archive.files) {
        if (file.name.startsWith('Files/Data/') && file.content.isNotEmpty) {
          // Remove 'Files/Data/' prefix to get relative path
          final relativePath = file.name.substring('Files/Data/'.length);

          // Skip if this is just a directory entry
          if (relativePath.isEmpty || relativePath.endsWith('/')) {
            continue;
          }

          // Extract the ID from the path
          // Scrivener uses patterns like: <ID>.rtf or Docs/<ID>/content.rtf
          String fileId;
          if (relativePath.contains('/')) {
            // File is in a subdirectory (e.g., "Docs/42/content.rtf" or "42/content.rtf")
            fileId = relativePath.split('/').first;
          } else {
            // File is at root level (e.g., "42.rtf")
            fileId = relativePath.replaceAll('.rtf', '');
          }

          try {
            final rawContent = utf8.decode(file.content as List<int>);
            // Convert RTF to plain text
            final content = rtfToPlainText(rawContent);
            textContents[fileId] = content;
            print('Loaded content for ID: $fileId from ${file.name}');
            print('  Raw content length: ${rawContent.length}, Plain text length: ${content.length}');
          } catch (e) {
            print('Error loading file ${file.name}: $e');
          }
        }
      }
      print('Loaded ${textContents.length} text contents');

      // Load research items from Files/Docs (PDFs/images/etc.).
      final researchItems = <String, ResearchItem>{};
      for (final file in archive.files) {
        if (!file.name.startsWith('Files/Docs/') || file.content.isEmpty) {
          continue;
        }

        final relativePath = file.name.substring('Files/Docs/'.length);
        if (relativePath.isEmpty || relativePath.endsWith('/')) {
          continue;
        }

        final pathSegments = relativePath.split('/');
        final baseName = pathSegments.isNotEmpty ? pathSegments.last : relativePath;
        final lastDot = baseName.lastIndexOf('.');
        final extension = lastDot == -1 ? '' : baseName.substring(lastDot + 1);

        final fileId = pathSegments.length > 1
            ? pathSegments.first
            : (lastDot == -1 ? baseName : baseName.substring(0, lastDot));

        if (fileId.isEmpty) {
          continue;
        }

        final bytes = Uint8List.fromList(file.content as List<int>);
        final now = DateTime.now();
        final type = ResearchItemType.fromExtension(extension);

        researchItems[fileId] = ResearchItem(
          id: fileId,
          title: binderTitleById[fileId] ?? fileId,
          type: type,
          data: bytes,
          mimeType: type.mimeTypePattern,
          fileSize: bytes.length,
          createdAt: now,
          modifiedAt: now,
        );
      }
      print('Loaded ${researchItems.length} research items');

      // Create project
      final projectPath = 'web_${projectName.replaceAll(' ', '_')}';
      final project = ScrivenerProject(
        name: projectName,
        path: projectPath,
        binderItems: binderItems,
        textContents: textContents,
        researchItems: researchItems,
        settings: ProjectSettings.defaults(),
      );

      // Save to storage
      await saveProject(project);

      return project;
    } catch (e) {
      print('Error importing project: $e');
      return null;
    }
  }

  /// Get total storage used in bytes
  int getStorageUsed() {
    int total = 0;
    for (final projectJson in _projects.values) {
      final jsonString = json.encode(projectJson);
      total += utf8.encode(jsonString).length;
    }
    return total;
  }

  /// Get storage used as human-readable string
  String getStorageUsedFormatted() {
    final bytes = getStorageUsed();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Create .scrivx XML content
  List<int> _createScrivxXml(ScrivenerProject project) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('ScrivenerProject', nest: () {
      builder.attribute('Version', '2.0');
      builder.attribute('Identifier', project.path);

      builder.element('Binder', nest: () {
        for (final item in project.binderItems) {
          _buildBinderItemXml(builder, item);
        }
      });
    });

    final xmlString = builder.buildDocument().toXmlString(pretty: true);
    return utf8.encode(xmlString);
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

  /// Convert BinderItemType to string for XML
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

  /// Parse binder items from XML
  List<BinderItem> _parseBinderItemsFromXml(XmlDocument document) {
    final binderElement = document.findAllElements('Binder').firstOrNull;
    if (binderElement == null) return [];

    final items = <BinderItem>[];
    for (final child in binderElement.children.whereType<XmlElement>()) {
      if (child.name.local == 'BinderItem') {
        final item = _parseBinderItemFromXml(child);
        if (item != null) items.add(item);
      }
    }
    return items;
  }

  /// Parse a single binder item from XML recursively
  BinderItem? _parseBinderItemFromXml(XmlElement element) {
    // Explicitly convert to plain strings to avoid XML namespace references
    final id = (element.getAttribute('ID') ?? '').toString();
    final type = (element.getAttribute('Type') ?? 'Text').toString();
    final titleElement = element.findElements('Title').firstOrNull;
    final title = (titleElement?.innerText ?? 'Untitled').toString();

    final children = <BinderItem>[];
    final childrenElement = element.findElements('Children').firstOrNull;
    if (childrenElement != null) {
      for (final child in childrenElement.children.whereType<XmlElement>()) {
        if (child.name.local == 'BinderItem') {
          final childItem = _parseBinderItemFromXml(child);
          if (childItem != null) children.add(childItem);
        }
      }
    }

    return BinderItem(
      id: id,
      title: title,
      type: _parseBinderItemType('BinderItemType.${type.toLowerCase()}'),
      children: children,
    );
  }

  /// Clear all error state
  void clearError() {
    notifyListeners();
  }
}
