import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/scrivener_project.dart';
import '../models/document_metadata.dart';
import '../utils/markdown_frontmatter.dart';

/// Converts projects between Scrivener (.scriv/.scrivx) and Writr (.writ/.writx) formats.
class ProjectConverter {
  /// Convert a Scrivener project to Writr format.
  ///
  /// Creates a new .writ directory at [outputPath] with all content converted
  /// from RTF to Markdown.
  ///
  /// Returns the path to the new .writ project directory.
  Future<String> scrivenerToWritr({
    required ScrivenerProject scrivenerProject,
    required String outputDirectory,
    String? newName,
  }) async {
    final projectName = newName ?? scrivenerProject.name;
    final writrPath = path.join(outputDirectory, '$projectName.writ');
    final writrDir = Directory(writrPath);

    // Create directory structure
    await writrDir.create(recursive: true);
    await Directory(path.join(writrPath, 'content')).create(recursive: true);
    await Directory(path.join(writrPath, 'research')).create(recursive: true);
    await Directory(path.join(writrPath, 'snapshots')).create(recursive: true);
    await Directory(path.join(writrPath, 'metadata')).create(recursive: true);

    // Convert and save text contents as Markdown
    await _convertTextContents(
      scrivenerProject,
      writrPath,
    );

    // Copy research items
    await _copyResearchItems(
      scrivenerProject,
      writrPath,
    );

    // Save document metadata
    await _saveDocumentMetadata(
      scrivenerProject,
      writrPath,
    );

    // Convert and save snapshots
    await _convertSnapshots(
      scrivenerProject,
      writrPath,
    );

    // Save .writx manifest
    await _saveWritxManifest(
      scrivenerProject,
      writrPath,
      projectName,
    );

    debugPrint('Converted Scrivener project to Writr format at: $writrPath');
    return writrPath;
  }

  /// Convert RTF text contents to Markdown files.
  Future<void> _convertTextContents(
    ScrivenerProject project,
    String writrPath,
  ) async {
    final contentDir = Directory(path.join(writrPath, 'content'));

    for (final entry in project.textContents.entries) {
      final docId = entry.key;
      final content = entry.value; // Already plain text (RTF was parsed on load)

      // Get metadata for frontmatter
      final metadata = project.documentMetadata[docId];
      final binderItem = _findBinderItem(project.binderItems, docId);

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
        if (metadata.status != DocumentStatus.noStatus) {
          frontmatter['status'] = metadata.status.name;
        }
      }

      final mdContent = writeMarkdownWithFrontmatter(
        frontmatter: frontmatter,
        content: content,
      );

      final mdFile = File(path.join(contentDir.path, '$docId.md'));
      await mdFile.writeAsString(mdContent);
    }
  }

  /// Copy research items to the new project.
  Future<void> _copyResearchItems(
    ScrivenerProject project,
    String writrPath,
  ) async {
    if (project.researchItems.isEmpty) return;

    final researchDir = Directory(path.join(writrPath, 'research'));
    final index = <String, dynamic>{};

    for (final entry in project.researchItems.entries) {
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

      // Copy file if it exists
      if (item.filePath != null) {
        final sourceFile = File(item.filePath!);
        if (await sourceFile.exists()) {
          final destFile = File(path.join(researchDir.path, fileName));
          await sourceFile.copy(destFile.path);
        }
      } else if (item.data != null) {
        // Write from memory
        final destFile = File(path.join(researchDir.path, fileName));
        await destFile.writeAsBytes(item.data!);
      }
    }

    // Save research index
    final indexFile = File(path.join(researchDir.path, 'index.json'));
    await indexFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(index),
    );
  }

  /// Save document metadata.
  Future<void> _saveDocumentMetadata(
    ScrivenerProject project,
    String writrPath,
  ) async {
    if (project.documentMetadata.isEmpty) return;

    final metadataDir = Directory(path.join(writrPath, 'metadata'));
    final data = <String, dynamic>{};

    for (final entry in project.documentMetadata.entries) {
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

  /// Convert and save snapshots.
  Future<void> _convertSnapshots(
    ScrivenerProject project,
    String writrPath,
  ) async {
    if (project.documentSnapshots.isEmpty) return;

    final snapshotsDir = Directory(path.join(writrPath, 'snapshots'));

    for (final entry in project.documentSnapshots.entries) {
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

  /// Save the .writx manifest file.
  Future<void> _saveWritxManifest(
    ScrivenerProject project,
    String writrPath,
    String projectName,
  ) async {
    final manifest = {
      'format': 'writx',
      'version': '1.0',
      'name': projectName,
      'uuid': DateTime.now().millisecondsSinceEpoch.toString(),
      'created': DateTime.now().toIso8601String(),
      'modified': DateTime.now().toIso8601String(),
      'binder': _binderItemsToJson(project.binderItems),
      'labels': project.labels.toJson(),
      'statuses': project.statuses.toJson(),
    };

    final writxFile = File(path.join(writrPath, '$projectName.writx'));
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

  BinderItem? _findBinderItem(List<BinderItem> items, String id) {
    for (final item in items) {
      if (item.id == id) return item;
      final found = _findBinderItem(item.children, id);
      if (found != null) return found;
    }
    return null;
  }
}

/// Detect the format of a project directory.
enum ProjectFormat {
  /// Scrivener format (.scriv with .scrivx)
  scrivener,

  /// Writr native format (.writ with .writx)
  writr,

  /// Unknown format
  unknown,
}

/// Detect the format of a project at the given path.
Future<ProjectFormat> detectProjectFormat(String projectPath) async {
  final dir = Directory(projectPath);
  if (!await dir.exists()) {
    return ProjectFormat.unknown;
  }

  final dirName = path.basename(projectPath).toLowerCase();

  // Check by directory extension first
  if (dirName.endsWith('.writ')) {
    // Look for .writx file
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.writx')) {
        return ProjectFormat.writr;
      }
    }
    // Fallback: if directory ends with .writ, treat as writr format
    // This handles cases where the project needs to be saved for the first time
    return ProjectFormat.writr;
  }

  if (dirName.endsWith('.scriv')) {
    // Verify .scrivx exists
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.scrivx')) {
        return ProjectFormat.scrivener;
      }
    }
    // Fallback: if directory ends with .scriv, treat as scrivener format
    return ProjectFormat.scrivener;
  }

  // Check by content (for directories without standard extensions)
  await for (final entity in dir.list()) {
    if (entity is File) {
      final fileName = entity.path.toLowerCase();
      if (fileName.endsWith('.writx')) {
        return ProjectFormat.writr;
      }
      if (fileName.endsWith('.scrivx')) {
        return ProjectFormat.scrivener;
      }
    }
  }

  return ProjectFormat.unknown;
}
