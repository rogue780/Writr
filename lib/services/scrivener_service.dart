import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;
import '../models/scrivener_project.dart';
import '../models/document_metadata.dart';
import '../models/snapshot.dart';
import '../models/research_item.dart';
import '../utils/rtf_parser.dart';

/// Project format mode - determines what operations are allowed.
enum ProjectMode {
  /// Native Writr format (.writ/.writx) - full read/write access
  native,

  /// Imported Scrivener project (.scriv/.scrivx) - RTF-only writes to prevent corruption
  scrivener,
}

class ScrivenerService extends ChangeNotifier {
  ScrivenerProject? _currentProject;
  bool _isLoading = false;
  String? _error;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  Function? _onAutoSave; // Callback for web storage auto-save

  // RTF round-tripping support (to preserve Scrivener formatting).
  final Map<String, String> _rtfContentsById = {};
  final Map<String, String> _contentFilePathById = {};
  final Set<String> _dirtyRtfIds = {};
  final Map<String, String> _rtfPatchErrorsById = {};

  // When we load an existing Scrivener project, avoid rewriting the `.scrivx`
  // unless we can do so without losing metadata.
  String? _loadedScrivxPath;
  bool _allowScrivxRewrite = false;
  bool _scrivxDirty = false;

  // Project mode - determines what operations are allowed.
  ProjectMode _projectMode = ProjectMode.native;

  ScrivenerProject? get currentProject => _currentProject;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  ProjectMode get projectMode => _projectMode;
  bool get isScrivenerMode => _projectMode == ProjectMode.scrivener;

  /// Clear the unsaved changes flag (used when saving via WritrService).
  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  /// Throws [StateError] if in Scrivener mode - used to block structural changes.
  ///
  /// In Scrivener mode, only text content edits are allowed to prevent
  /// corrupting imported Scrivener projects.
  void _ensureNotScrivenerMode(String operation) {
    if (_projectMode == ProjectMode.scrivener) {
      throw StateError(
        'Cannot $operation in Scrivener-compatible mode. '
        'Convert to Writr format (.writ) to make structural changes.',
      );
    }
  }

  /// Set a callback for auto-save (used by web storage)
  void setAutoSaveCallback(Function callback) {
    _onAutoSave = callback;
  }

  /// Load a Scrivener project from a .scriv directory
  Future<void> loadProject(String projectPath) async {
    _isLoading = true;
    _error = null;
    _rtfContentsById.clear();
    _contentFilePathById.clear();
    _dirtyRtfIds.clear();
    _rtfPatchErrorsById.clear();
    _loadedScrivxPath = null;
    _allowScrivxRewrite = false;
    _scrivxDirty = false;
    _projectMode = ProjectMode.scrivener; // Imported Scrivener project - restricted mode
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
      _loadedScrivxPath = scrivxFile.path;

      // Parse the .scrivx XML file
      final xmlContent = await scrivxFile.readAsString();
      final document = XmlDocument.parse(xmlContent);

      // Parse binder items
      final binderItems = _parseBinderItems(document);

      // Load text contents from Files/Data directory
      final textContents = await _loadTextContents(projectDir);

      // Load research items (PDFs, images, web archives) from project files
      final researchItems = await _loadResearchItems(projectDir, binderItems);

      // Create project
      final projectName = path.basenameWithoutExtension(scrivxFile.path);
      _currentProject = ScrivenerProject(
        name: projectName,
        path: projectPath,
        binderItems: binderItems,
        textContents: textContents,
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

  /// Set a project directly (useful for web platform)
  ///
  /// By default, sets mode to [ProjectMode.scrivener] for imported projects.
  /// Pass [mode] explicitly to override (e.g., for native .writ projects).
  void setProject(ScrivenerProject project, {ProjectMode? mode}) {
    _currentProject = project;
    _error = null;
    _hasUnsavedChanges = false;
    _rtfContentsById.clear();
    _contentFilePathById.clear();
    _dirtyRtfIds.clear();
    _rtfPatchErrorsById.clear();
    _loadedScrivxPath = null;
    _scrivxDirty = false;
    _projectMode = mode ?? ProjectMode.scrivener; // Default to scrivener mode for imports
    notifyListeners();
  }

  /// Trigger auto-save with debouncing
  void _triggerAutoSave() {
    _hasUnsavedChanges = true;
    notifyListeners();

    // Cancel existing timer
    _autoSaveTimer?.cancel();

    // Start new timer (2 seconds delay)
    _autoSaveTimer = Timer(const Duration(seconds: 2), () async {
      if (_onAutoSave != null && _currentProject != null) {
        try {
          await _onAutoSave!(_currentProject!);
          _hasUnsavedChanges = false;
          notifyListeners();
        } catch (e) {
          print('Auto-save error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
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
    final id = element.getAttribute('UUID') ?? element.getAttribute('ID') ?? '';
    final type = element.getAttribute('Type') ?? 'Text';
    final title = element.findElements('Title').firstOrNull?.innerText ?? 'Untitled';

    debugPrint('Parsed binder item: ID=$id, Type=$type, Title=$title');

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
    final normalized = type.toLowerCase();
    if (normalized == 'folder' || normalized.endsWith('folder')) {
      return BinderItemType.folder;
    }
    switch (normalized) {
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
          // Get relative path from Data directory
          final relativePath = path.relative(entity.path, from: dataDir.path);

          final fileName = path.basename(entity.path).toLowerCase();
          final isContentFile = fileName == 'content.rtf' || fileName == 'content.txt';

          final pathSegments = path.split(relativePath);
          final isLegacyRootTextFile = pathSegments.length == 1 &&
              (fileName.endsWith('.rtf') || fileName.endsWith('.txt'));

          if (!isContentFile && !isLegacyRootTextFile) {
            continue;
          }

          // Extract the ID from the path
          // Scrivener uses patterns like: <ID>.rtf or Docs/<ID>/content.rtf
          String fileId;
          if (pathSegments.length == 1) {
            // File is at root level (e.g., "<ID>.rtf")
            fileId = path.basenameWithoutExtension(pathSegments.first);
          } else {
            // File is in a subdirectory (e.g., "<ID>/content.rtf" or "Docs/<ID>/content.rtf")
            final uuidPattern = RegExp(
              r'^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$',
            );
            final numericPattern = RegExp(r'^\d+$');

            final first = pathSegments.first;
            final second = pathSegments.length > 1 ? pathSegments[1] : null;

            if (uuidPattern.hasMatch(first) || numericPattern.hasMatch(first)) {
              fileId = first;
            } else if (second != null &&
                (uuidPattern.hasMatch(second) || numericPattern.hasMatch(second))) {
              fileId = second;
            } else {
              fileId = first;
            }
          }

          final rawContent = await entity.readAsString();
          final content = fileName.endsWith('.rtf') ? rtfToPlainText(rawContent) : rawContent;
          textContents[fileId] = content;
          _contentFilePathById[fileId] = entity.path;
          if (fileName.endsWith('.rtf')) {
            _rtfContentsById[fileId] = rawContent;
          }
          debugPrint('Loaded content for ID: $fileId from ${entity.path}');
          debugPrint('  Raw content length: ${rawContent.length}, Plain text length: ${content.length}');
        } catch (e) {
          // Skip files that can't be read
          debugPrint('Error reading file ${entity.path}: $e');
        }
      }
    }

    debugPrint('Loaded ${textContents.length} text contents');
    return textContents;
  }

  Future<Map<String, ResearchItem>> _loadResearchItems(
    Directory projectDir,
    List<BinderItem> binderItems,
  ) async {
    final researchBinderItems = <BinderItem>[];
    void collect(List<BinderItem> items) {
      for (final item in items) {
        if (item.isResearchItem) {
          researchBinderItems.add(item);
        }
        if (item.children.isNotEmpty) {
          collect(item.children);
        }
      }
    }
    collect(binderItems);

    if (researchBinderItems.isEmpty) {
      return {};
    }

    final fileIndex = await _indexResearchFiles(projectDir);
    final researchItems = <String, ResearchItem>{};

    for (final binderItem in researchBinderItems) {
      final file = fileIndex[binderItem.id];
      if (file == null) {
        continue;
      }

      try {
        final stat = await file.stat();
        final ext = path.extension(file.path).toLowerCase();
        final type = _binderTypeToResearchType(binderItem.type, ext);

        researchItems[binderItem.id] = ResearchItem(
          id: binderItem.id,
          title: binderItem.title,
          type: type,
          filePath: file.path,
          mimeType: _mimeTypeForExtension(ext),
          fileSize: stat.size,
          createdAt: stat.modified,
          modifiedAt: stat.modified,
        );
      } catch (e) {
        debugPrint('Error loading research file for ${binderItem.id}: $e');
      }
    }

    debugPrint('Loaded ${researchItems.length} research items');
    return researchItems;
  }

  Future<Map<String, File>> _indexResearchFiles(Directory projectDir) async {
    // Scrivener stores non-text documents (PDFs/images/etc.) in `Files/Docs`
    // and sometimes in nested directories under it.
    final candidateDirs = <String>[
      path.join(projectDir.path, 'Files', 'Docs'),
      path.join(projectDir.path, 'Files', 'Data'),
    ];

    const allowedExtensions = <String>{
      '.pdf',
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.tif',
      '.tiff',
      '.webarchive',
      '.mhtml',
    };

    final index = <String, File>{};

    for (final dirPath in candidateDirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        continue;
      }

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;

        final ext = path.extension(entity.path).toLowerCase();
        if (!allowedExtensions.contains(ext)) continue;

        final base = path.basenameWithoutExtension(entity.path);
        final parent = path.basename(path.dirname(entity.path));

        index.putIfAbsent(base, () => entity);
        index.putIfAbsent(parent, () => entity);
      }
    }

    return index;
  }

  ResearchItemType _binderTypeToResearchType(
    BinderItemType binderType,
    String fileExtension,
  ) {
    switch (binderType) {
      case BinderItemType.pdf:
        return ResearchItemType.pdf;
      case BinderItemType.image:
        return ResearchItemType.image;
      case BinderItemType.webArchive:
        return ResearchItemType.webArchive;
      case BinderItemType.folder:
      case BinderItemType.text:
        // Not expected here, but fall back to file extension.
        return ResearchItemType.fromExtension(fileExtension);
    }
  }

  String _mimeTypeForExtension(String extension) {
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      case '.tif':
      case '.tiff':
        return 'image/tiff';
      case '.webarchive':
        return 'application/x-webarchive';
      case '.mhtml':
        return 'multipart/related';
      default:
        return 'application/octet-stream';
    }
  }

  /// Save the current project
  Future<void> saveProject() async {
    if (_currentProject == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // In Scrivener mode, ONLY save RTF content changes - nothing else
      if (_projectMode == ProjectMode.scrivener) {
        await _saveRtfContentChangesOnly();
        _isLoading = false;
        _hasUnsavedChanges = false;
        notifyListeners();
        return;
      }

      // Native mode: full save
      if (_rtfPatchErrorsById.isNotEmpty) {
        final ids = _rtfPatchErrorsById.keys.take(3).join(', ');
        throw Exception(
          'Cannot save: one or more documents could not be updated without losing Scrivener formatting (e.g. $ids).',
        );
      }

      final projectDir = Directory(_currentProject!.path);

      // Save text contents to Files/Data directory
      await _saveTextContents(projectDir, _currentProject!.textContents);

      // Save research items (PDFs/images/etc.) to Files/Docs directory
      await _saveResearchItems(projectDir);

      // Preserve existing .scrivx files unless we can update them safely.
      final scrivxPath = _loadedScrivxPath ??
          path.join(projectDir.path, '${_currentProject!.name}.scrivx');
      final scrivxExists = await File(scrivxPath).exists();
      if (!scrivxExists) {
        await _saveScrivxFile(projectDir, _currentProject!);
        _loadedScrivxPath = scrivxPath;
        _allowScrivxRewrite = true;
        _scrivxDirty = false;
      } else if (_scrivxDirty) {
        if (_allowScrivxRewrite) {
          await _saveScrivxFile(projectDir, _currentProject!);
          _scrivxDirty = false;
        } else {
          throw Exception(
            'Saving binder changes back to an existing Scrivener project is not supported yet (would risk losing .scrivx metadata).',
          );
        }
      }

      _isLoading = false;
      _dirtyRtfIds.clear();
      _hasUnsavedChanges = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save only modified RTF content in Scrivener mode.
  ///
  /// This is the restricted save for imported Scrivener projects. It ONLY writes
  /// RTF files that have been modified, preserving all other files in the project.
  Future<void> _saveRtfContentChangesOnly() async {
    if (_currentProject == null) return;

    // Check for RTF patching errors first
    if (_rtfPatchErrorsById.isNotEmpty) {
      final ids = _rtfPatchErrorsById.keys.take(3).join(', ');
      throw Exception(
        'Cannot save: one or more documents could not be updated without losing '
        'Scrivener formatting (e.g. $ids). These documents have been skipped.',
      );
    }

    // Only write files that are marked as dirty
    for (final itemId in _dirtyRtfIds) {
      final filePath = _contentFilePathById[itemId];
      if (filePath == null) continue;

      final rtfContent = _rtfContentsById[itemId];
      if (rtfContent == null) continue;

      final file = File(filePath);
      await file.writeAsString(rtfContent);
      debugPrint('Scrivener mode: saved RTF changes to $filePath');
    }

    _dirtyRtfIds.clear();
  }

  /// Save text contents to Files/Data directory
  Future<void> _saveTextContents(
    Directory projectDir,
    Map<String, String> textContents,
  ) async {
    final dataDir = Directory(path.join(projectDir.path, 'Files', 'Data'));
    await dataDir.create(recursive: true);

    for (final entry in textContents.entries) {
      final existingPath = _contentFilePathById[entry.key];
      final File file;
      if (existingPath != null) {
        file = File(existingPath);
      } else {
        final scrivenerDir = Directory(path.join(dataDir.path, entry.key));
        file = (await scrivenerDir.exists())
            ? File(path.join(scrivenerDir.path, 'content.rtf'))
            : File(path.join(dataDir.path, '${entry.key}.rtf'));
      }

      final shouldWrite =
          _dirtyRtfIds.contains(entry.key) ? true : !await file.exists();
      if (!shouldWrite) {
        continue;
      }

      await file.parent.create(recursive: true);

      if (file.path.toLowerCase().endsWith('.rtf')) {
        final rtf = _rtfContentsById[entry.key] ?? plainTextToRtf(entry.value);
        await file.writeAsString(rtf);
      } else {
        await file.writeAsString(entry.value);
      }

      _contentFilePathById[entry.key] = file.path;
    }
  }

  Future<void> _saveResearchItems(Directory projectDir) async {
    if (_currentProject == null) return;

    final docsDir = Directory(path.join(projectDir.path, 'Files', 'Docs'));
    await docsDir.create(recursive: true);

    final updatedItems = Map<String, ResearchItem>.from(_currentProject!.researchItems);
    var changed = false;

    for (final entry in _currentProject!.researchItems.entries) {
      final item = entry.value;
      if (item.data == null || item.data!.isEmpty) {
        continue;
      }

      // If this item already points to a file, assume it is the source of truth
      // unless the file is missing (e.g. a newly imported item without path).
      final existingPath = item.filePath;
      if (existingPath != null && existingPath.isNotEmpty) {
        final file = File(existingPath);
        if (await file.exists()) {
          continue;
        }
      }

      final fileName = '${item.id}.${item.fileExtension}';
      final file = File(path.join(docsDir.path, fileName));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(item.data!, flush: true);
      final stat = await file.stat();

      updatedItems[item.id] = ResearchItem(
        id: item.id,
        title: item.title,
        type: item.type,
        filePath: file.path,
        data: item.data,
        mimeType: item.mimeType,
        fileSize: stat.size,
        createdAt: item.createdAt,
        modifiedAt: stat.modified,
        description: item.description,
        linkedDocumentIds: item.linkedDocumentIds,
      );
      changed = true;
    }

    if (!changed) return;

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: _currentProject!.binderItems,
      textContents: _currentProject!.textContents,
      documentMetadata: _currentProject!.documentMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: updatedItems,
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );
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
      _loadedScrivxPath = path.join(projectDir.path, '$name.scrivx');
      _allowScrivxRewrite = true;
      _scrivxDirty = true;
      _projectMode = ProjectMode.native; // New projects are native - full access

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

    final currentPath = _contentFilePathById[itemId];
    final isRtf = (currentPath?.toLowerCase().endsWith('.rtf') ?? false) ||
        _rtfContentsById.containsKey(itemId);

    if (isRtf) {
      final baseRtf = _rtfContentsById[itemId] ??
          plainTextToRtf(_currentProject!.textContents[itemId] ?? '');
      try {
        final updatedRtf = updateRtfPlainTextPreservingFormatting(
          rtfContent: baseRtf,
          plainText: content,
        );
        if (updatedRtf != baseRtf) {
          _rtfContentsById[itemId] = updatedRtf;
          _dirtyRtfIds.add(itemId);
        }
        _rtfPatchErrorsById.remove(itemId);
      } catch (e) {
        _rtfPatchErrorsById[itemId] = e.toString();
      }
    }

    final updatedContents =
        Map<String, String>.from(_currentProject!.textContents);
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

    notifyListeners();
    _triggerAutoSave(); // Trigger auto-save when content changes
  }

  /// Update metadata for a document
  ///
  /// Throws [StateError] in Scrivener mode - metadata changes are not allowed.
  void updateDocumentMetadata(String documentId, DocumentMetadata metadata) {
    if (_currentProject == null) return;
    _ensureNotScrivenerMode('modify document metadata');

    final updatedMetadata =
        Map<String, DocumentMetadata>.from(_currentProject!.documentMetadata);
    updatedMetadata[documentId] = metadata;

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: _currentProject!.binderItems,
      textContents: _currentProject!.textContents,
      documentMetadata: updatedMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: _currentProject!.researchItems,
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );

    notifyListeners();
    _triggerAutoSave();
  }

  /// Get metadata for a document
  DocumentMetadata getDocumentMetadata(String documentId) {
    if (_currentProject == null) {
      return DocumentMetadata.empty(documentId);
    }
    return _currentProject!.getMetadata(documentId);
  }

  /// Get snapshots for a document
  List<DocumentSnapshot> getDocumentSnapshots(String documentId) {
    if (_currentProject == null) return [];
    return _currentProject!.getSnapshots(documentId);
  }

  /// Get the raw RTF content for a document.
  ///
  /// Returns the original RTF content if available, or null if the document
  /// doesn't exist or wasn't loaded from RTF.
  String? getRawRtfContent(String documentId) {
    return _rtfContentsById[documentId];
  }

  /// Check if a document has RTF content.
  bool hasRtfContent(String documentId) {
    return _rtfContentsById.containsKey(documentId);
  }

  /// Update text content with raw RTF.
  ///
  /// This is used by the ScrivenerEditor which handles RTF round-tripping
  /// internally. The provided RTF content replaces the stored RTF directly.
  void updateTextContentWithRtf(String itemId, String rtfContent, String plainText) {
    if (_currentProject == null) return;

    // Store the RTF content directly
    _rtfContentsById[itemId] = rtfContent;
    _dirtyRtfIds.add(itemId);

    // Update plain text contents
    final updatedContents =
        Map<String, String>.from(_currentProject!.textContents);
    updatedContents[itemId] = plainText;

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

    notifyListeners();
    _triggerAutoSave();
  }

  /// Create a snapshot of the current document content
  void createSnapshot(String documentId, String documentTitle, {String? note}) {
    if (_currentProject == null) return;

    final content = _currentProject!.textContents[documentId] ?? '';
    final snapshot = DocumentSnapshot.create(
      documentId: documentId,
      title: documentTitle,
      content: content,
      note: note,
    );

    _currentProject = _currentProject!.withAddedSnapshot(documentId, snapshot);
    notifyListeners();
    _triggerAutoSave();
  }

  /// Delete a snapshot
  void deleteSnapshot(String documentId, String snapshotId) {
    if (_currentProject == null) return;

    _currentProject = _currentProject!.withRemovedSnapshot(documentId, snapshotId);
    notifyListeners();
    _triggerAutoSave();
  }

  /// Restore document content from a snapshot
  void restoreFromSnapshot(String documentId, DocumentSnapshot snapshot) {
    if (_currentProject == null) return;

    // First create a snapshot of current content before restoring
    final currentContent = _currentProject!.textContents[documentId] ?? '';
    if (currentContent.isNotEmpty) {
      final binderItem = _findBinderItem(_currentProject!.binderItems, documentId);
      final title = binderItem?.title ?? 'Document';
      createSnapshot(documentId, title, note: 'Before restoring from "${snapshot.title}"');
    }

    // Now restore the content from the snapshot
    updateTextContent(documentId, snapshot.content);
  }

  /// Find a binder item by ID recursively
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

  /// Add a new binder item (folder or document)
  ///
  /// Throws [StateError] in Scrivener mode - structural changes are not allowed.
  void addBinderItem({
    required String title,
    required BinderItemType type,
    String? parentId,
  }) {
    if (_currentProject == null) return;
    _ensureNotScrivenerMode('add documents or folders');
    _scrivxDirty = true;

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

    notifyListeners();
  }

  /// Rename a binder item
  ///
  /// Throws [StateError] in Scrivener mode - structural changes are not allowed.
  void renameBinderItem(String itemId, String newTitle) {
    if (_currentProject == null) return;
    _ensureNotScrivenerMode('rename documents or folders');
    _scrivxDirty = true;

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

    notifyListeners();
  }

  /// Delete a binder item
  ///
  /// Throws [StateError] in Scrivener mode - structural changes are not allowed.
  void deleteBinderItem(String itemId) {
    if (_currentProject == null) return;
    _ensureNotScrivenerMode('delete documents or folders');
    _scrivxDirty = true;

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

  // ==================== Research Item Methods ====================

  /// Get a research item by ID
  ResearchItem? getResearchItem(String itemId) {
    if (_currentProject == null) return null;
    return _currentProject!.getResearchItem(itemId);
  }

  /// Get all research items
  List<ResearchItem> getAllResearchItems() {
    if (_currentProject == null) return [];
    return _currentProject!.allResearchItems;
  }

  /// Add a research item and create corresponding binder item
  ///
  /// Throws [StateError] in Scrivener mode - structural changes are not allowed.
  void addResearchItem(ResearchItem item, {String? parentFolderId}) {
    if (_currentProject == null) return;
    _ensureNotScrivenerMode('add research items');
    _scrivxDirty = true;

    // Determine the correct binder item type based on research type
    final binderType = _researchTypeToBinderType(item.type);

    // Create the binder item for this research
    final binderItem = BinderItem(
      id: item.id,
      title: item.title,
      type: binderType,
      children: [],
    );

    // Find the Research folder or use provided parent
    String? targetParentId = parentFolderId;
    if (targetParentId == null) {
      // Find the Research folder
      final researchFolder = _findResearchFolder(_currentProject!.binderItems);
      targetParentId = researchFolder?.id;
    }

    // Add binder item
    List<BinderItem> updatedItems;
    if (targetParentId != null) {
      updatedItems = _addItemToParent(
        _currentProject!.binderItems,
        targetParentId,
        binderItem,
      );
    } else {
      updatedItems = [..._currentProject!.binderItems, binderItem];
    }

    // Add research item to project
    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: updatedItems,
      textContents: _currentProject!.textContents,
      documentMetadata: _currentProject!.documentMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: {
        ..._currentProject!.researchItems,
        item.id: item,
      },
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );

    notifyListeners();
    _triggerAutoSave();
  }

  /// Update a research item
  void updateResearchItem(ResearchItem item) {
    if (_currentProject == null) return;

    _currentProject = _currentProject!.withUpdatedResearchItem(item);
    notifyListeners();
    _triggerAutoSave();
  }

  /// Delete a research item and its binder entry
  ///
  /// Throws [StateError] in Scrivener mode - structural changes are not allowed.
  void deleteResearchItem(String itemId) {
    if (_currentProject == null) return;
    _ensureNotScrivenerMode('delete research items');
    _scrivxDirty = true;

    // Remove binder item
    final updatedItems = _deleteItemRecursive(
      _currentProject!.binderItems,
      itemId,
    );

    // Remove research item
    final newResearchItems = Map<String, ResearchItem>.from(
      _currentProject!.researchItems,
    );
    newResearchItems.remove(itemId);

    _currentProject = ScrivenerProject(
      name: _currentProject!.name,
      path: _currentProject!.path,
      binderItems: updatedItems,
      textContents: _currentProject!.textContents,
      documentMetadata: _currentProject!.documentMetadata,
      documentSnapshots: _currentProject!.documentSnapshots,
      researchItems: newResearchItems,
      documentComments: _currentProject!.documentComments,
      documentFootnotes: _currentProject!.documentFootnotes,
      footnoteSettings: _currentProject!.footnoteSettings,
      settings: _currentProject!.settings,
      labels: _currentProject!.labels,
      statuses: _currentProject!.statuses,
    );

    notifyListeners();
    _triggerAutoSave();
  }

  /// Link a research item to a document
  void linkResearchToDocument(String researchId, String documentId) {
    if (_currentProject == null) return;

    final item = _currentProject!.getResearchItem(researchId);
    if (item == null) return;

    final updatedItem = item.withLinkedDocument(documentId);
    _currentProject = _currentProject!.withUpdatedResearchItem(updatedItem);
    notifyListeners();
    _triggerAutoSave();
  }

  /// Unlink a research item from a document
  void unlinkResearchFromDocument(String researchId, String documentId) {
    if (_currentProject == null) return;

    final item = _currentProject!.getResearchItem(researchId);
    if (item == null) return;

    final updatedItem = item.withUnlinkedDocument(documentId);
    _currentProject = _currentProject!.withUpdatedResearchItem(updatedItem);
    notifyListeners();
    _triggerAutoSave();
  }

  /// Get research items linked to a document
  List<ResearchItem> getLinkedResearchItems(String documentId) {
    if (_currentProject == null) return [];
    return _currentProject!.getLinkedResearchItems(documentId);
  }

  /// Find the Research folder in binder items
  BinderItem? _findResearchFolder(List<BinderItem> items) {
    for (final item in items) {
      if (item.isFolder && item.title.toLowerCase() == 'research') {
        return item;
      }
      if (item.children.isNotEmpty) {
        final found = _findResearchFolder(item.children);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Convert research item type to binder item type
  BinderItemType _researchTypeToBinderType(ResearchItemType type) {
    switch (type) {
      case ResearchItemType.pdf:
        return BinderItemType.pdf;
      case ResearchItemType.image:
        return BinderItemType.image;
      case ResearchItemType.webArchive:
        return BinderItemType.webArchive;
      case ResearchItemType.text:
      case ResearchItemType.markdown:
        return BinderItemType.text;
    }
  }
}
