/// Factory for creating test data used across integration tests
library;

import 'package:writr/models/scrivener_project.dart';
import 'package:writr/models/document_metadata.dart';
import 'package:writr/models/snapshot.dart';
import 'package:writr/models/comment.dart';
import 'package:writr/models/footnote.dart';
import 'package:writr/models/keyword.dart';
import 'package:writr/models/collection.dart';
import 'package:writr/models/target.dart';

/// Factory class for creating test data
class TestDataFactory {
  static int _idCounter = 0;

  static String _generateId() => 'test_${++_idCounter}';

  /// Creates a minimal test project with basic structure
  static ScrivenerProject createMinimalProject({
    String? name,
    String? path,
  }) {
    final projectName = name ?? 'Test Project';
    final projectPath = path ?? '/test/path/$projectName.writ';

    return ScrivenerProject.empty(projectName, projectPath);
  }

  /// Creates a fully populated test project with documents, metadata, etc.
  static ScrivenerProject createFullProject({
    String? name,
    int documentCount = 3,
    int folderCount = 2,
  }) {
    final projectName = name ?? 'Full Test Project';
    final projectPath = '/test/path/${projectName.replaceAll(' ', '_')}.writ';

    // Create manuscript with chapters
    final chapters = <BinderItem>[];
    final textContents = <String, String>{};
    final metadata = <String, DocumentMetadata>{};

    for (var i = 0; i < folderCount; i++) {
      final chapterId = _generateId();
      final scenes = <BinderItem>[];

      for (var j = 0; j < documentCount; j++) {
        final sceneId = _generateId();
        final scene = BinderItem(
          id: sceneId,
          title: 'Scene ${j + 1}',
          type: BinderItemType.text,
        );
        scenes.add(scene);

        // Add content
        textContents[sceneId] =
            'This is the content for Chapter ${i + 1}, Scene ${j + 1}.\n\n'
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
            'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';

        // Add metadata
        metadata[sceneId] = DocumentMetadata(
          documentId: sceneId,
          synopsis: 'Synopsis for scene ${j + 1}',
          notes: 'Notes for scene ${j + 1}',
          label: DocumentLabel.blue,
          status: DocumentStatus.firstDraft,
          includeInCompile: true,
        );
      }

      final chapter = BinderItem(
        id: chapterId,
        title: 'Chapter ${i + 1}',
        type: BinderItemType.folder,
        children: scenes,
      );
      chapters.add(chapter);
    }

    final manuscript = BinderItem(
      id: _generateId(),
      title: 'Manuscript',
      type: BinderItemType.folder,
      children: chapters,
    );

    final research = BinderItem(
      id: _generateId(),
      title: 'Research',
      type: BinderItemType.folder,
      children: [],
    );

    final characters = BinderItem(
      id: _generateId(),
      title: 'Characters',
      type: BinderItemType.folder,
      children: [
        BinderItem(
          id: _generateId(),
          title: 'Protagonist',
          type: BinderItemType.text,
        ),
        BinderItem(
          id: _generateId(),
          title: 'Antagonist',
          type: BinderItemType.text,
        ),
      ],
    );

    return ScrivenerProject(
      name: projectName,
      path: projectPath,
      binderItems: [manuscript, research, characters],
      textContents: textContents,
      documentMetadata: metadata,
      settings: ProjectSettings.defaults(),
      labels: ProjectLabels(),
      statuses: ProjectStatuses(),
    );
  }

  /// Creates a test document/binder item
  static BinderItem createDocument({
    String? id,
    String? title,
    String? content,
    List<BinderItem>? children,
  }) {
    return BinderItem(
      id: id ?? _generateId(),
      title: title ?? 'Test Document',
      type: children != null ? BinderItemType.folder : BinderItemType.text,
      children: children ?? const [],
      textContent: content,
    );
  }

  /// Creates a test folder with optional children
  static BinderItem createFolder({
    String? id,
    String? title,
    List<BinderItem>? children,
  }) {
    return BinderItem(
      id: id ?? _generateId(),
      title: title ?? 'Test Folder',
      type: BinderItemType.folder,
      children: children ?? [],
    );
  }

  /// Creates test document metadata
  static DocumentMetadata createMetadata({
    String? documentId,
    String? synopsis,
    String? notes,
    DocumentLabel? label,
    DocumentStatus? status,
    bool includeInCompile = true,
  }) {
    return DocumentMetadata(
      documentId: documentId ?? _generateId(),
      synopsis: synopsis ?? 'Test synopsis',
      notes: notes ?? 'Test notes',
      label: label,
      status: status ?? DocumentStatus.noStatus,
      includeInCompile: includeInCompile,
    );
  }

  /// Creates a test snapshot
  static DocumentSnapshot createSnapshot({
    String? id,
    String? documentId,
    String? content,
    DateTime? createdAt,
    String? title,
  }) {
    return DocumentSnapshot(
      id: id ?? _generateId(),
      documentId: documentId ?? _generateId(),
      content: content ?? 'Snapshot content',
      createdAt: createdAt ?? DateTime.now(),
      title: title ?? 'Snapshot',
    );
  }

  /// Creates a test comment
  static DocumentComment createComment({
    String? id,
    String? documentId,
    String? commentText,
    int startOffset = 0,
    int endOffset = 10,
    bool isResolved = false,
  }) {
    final now = DateTime.now();
    return DocumentComment(
      id: id ?? _generateId(),
      documentId: documentId ?? _generateId(),
      commentText: commentText ?? 'Test comment',
      startOffset: startOffset,
      endOffset: endOffset,
      isResolved: isResolved,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Creates a test footnote
  static DocumentFootnote createFootnote({
    String? id,
    String? documentId,
    String? content,
    int anchorOffset = 0,
    FootnoteType type = FootnoteType.footnote,
  }) {
    final now = DateTime.now();
    return DocumentFootnote(
      id: id ?? _generateId(),
      documentId: documentId ?? _generateId(),
      content: content ?? 'Footnote text',
      anchorOffset: anchorOffset,
      type: type,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Creates a test keyword
  static Keyword createKeyword({
    String? id,
    String? name,
    int? colorValue,
    String? parentId,
  }) {
    return Keyword(
      id: id ?? _generateId(),
      name: name ?? 'Test Keyword',
      colorValue: colorValue ?? 0xFFE57373,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a test collection
  static DocumentCollection createCollection({
    String? id,
    String? name,
    List<String>? documentIds,
    bool isSmartCollection = false,
    String? searchQuery,
  }) {
    final now = DateTime.now();
    return DocumentCollection(
      id: id ?? _generateId(),
      name: name ?? 'Test Collection',
      type: isSmartCollection ? CollectionType.search : CollectionType.manual,
      documentIds: documentIds ?? [],
      isSmartCollection: isSmartCollection,
      searchQuery: searchQuery,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Creates a test writing target
  static WritingTarget createTarget({
    String? id,
    String? name,
    TargetType type = TargetType.session,
    int targetCount = 1000,
    TargetUnit unit = TargetUnit.words,
    TargetPeriod? period,
  }) {
    return WritingTarget(
      id: id ?? _generateId(),
      name: name ?? 'Test Target',
      type: type,
      targetCount: targetCount,
      unit: unit,
      period: period ?? TargetPeriod.daily,
      createdAt: DateTime.now(),
    );
  }

  /// Resets the ID counter (useful between tests)
  static void reset() {
    _idCounter = 0;
  }
}
