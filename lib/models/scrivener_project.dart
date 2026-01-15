import 'document_metadata.dart';
import 'snapshot.dart';
import 'research_item.dart';
import 'comment.dart';
import 'footnote.dart';

class ScrivenerProject {
  final String name;
  final String path;
  final List<BinderItem> binderItems;
  final Map<String, String> textContents; // ID -> content
  final Map<String, DocumentMetadata> documentMetadata; // ID -> metadata
  final Map<String, List<DocumentSnapshot>> documentSnapshots; // ID -> snapshots
  final Map<String, ResearchItem> researchItems; // ID -> research item
  final Map<String, List<DocumentComment>> documentComments; // ID -> comments
  final Map<String, List<DocumentFootnote>> documentFootnotes; // ID -> footnotes
  final FootnoteSettings footnoteSettings;
  final ProjectSettings settings;
  final ProjectLabels labels;
  final ProjectStatuses statuses;

  ScrivenerProject({
    required this.name,
    required this.path,
    required this.binderItems,
    required this.textContents,
    Map<String, DocumentMetadata>? documentMetadata,
    Map<String, List<DocumentSnapshot>>? documentSnapshots,
    Map<String, ResearchItem>? researchItems,
    Map<String, List<DocumentComment>>? documentComments,
    Map<String, List<DocumentFootnote>>? documentFootnotes,
    FootnoteSettings? footnoteSettings,
    required this.settings,
    ProjectLabels? labels,
    ProjectStatuses? statuses,
  })  : documentMetadata = documentMetadata ?? {},
        documentSnapshots = documentSnapshots ?? {},
        researchItems = researchItems ?? {},
        documentComments = documentComments ?? {},
        documentFootnotes = documentFootnotes ?? {},
        footnoteSettings = footnoteSettings ?? const FootnoteSettings(),
        labels = labels ?? ProjectLabels(),
        statuses = statuses ?? ProjectStatuses();

  /// Get metadata for a document, creating default if not exists
  DocumentMetadata getMetadata(String documentId) {
    return documentMetadata[documentId] ??
        DocumentMetadata.empty(documentId);
  }

  /// Create a copy with updated metadata for a document
  ScrivenerProject withUpdatedMetadata(
      String documentId, DocumentMetadata metadata) {
    final newMetadata = Map<String, DocumentMetadata>.from(documentMetadata);
    newMetadata[documentId] = metadata;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: newMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: documentComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Get snapshots for a document
  List<DocumentSnapshot> getSnapshots(String documentId) {
    return documentSnapshots[documentId] ?? [];
  }

  /// Create a copy with a new snapshot added
  ScrivenerProject withAddedSnapshot(String documentId, DocumentSnapshot snapshot) {
    final newSnapshots = Map<String, List<DocumentSnapshot>>.from(documentSnapshots);
    final docSnapshots = List<DocumentSnapshot>.from(newSnapshots[documentId] ?? []);
    docSnapshots.insert(0, snapshot); // Add to beginning (most recent first)
    newSnapshots[documentId] = docSnapshots;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: newSnapshots,
      researchItems: researchItems,
      documentComments: documentComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with a snapshot removed
  ScrivenerProject withRemovedSnapshot(String documentId, String snapshotId) {
    final newSnapshots = Map<String, List<DocumentSnapshot>>.from(documentSnapshots);
    final docSnapshots = List<DocumentSnapshot>.from(newSnapshots[documentId] ?? []);
    docSnapshots.removeWhere((s) => s.id == snapshotId);
    newSnapshots[documentId] = docSnapshots;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: newSnapshots,
      researchItems: researchItems,
      documentComments: documentComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Get a research item by ID
  ResearchItem? getResearchItem(String itemId) {
    return researchItems[itemId];
  }

  /// Get all research items
  List<ResearchItem> get allResearchItems => researchItems.values.toList();

  /// Create a copy with a new research item added
  ScrivenerProject withAddedResearchItem(ResearchItem item) {
    final newResearchItems = Map<String, ResearchItem>.from(researchItems);
    newResearchItems[item.id] = item;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: newResearchItems,
      documentComments: documentComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with an updated research item
  ScrivenerProject withUpdatedResearchItem(ResearchItem item) {
    final newResearchItems = Map<String, ResearchItem>.from(researchItems);
    newResearchItems[item.id] = item;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: newResearchItems,
      documentComments: documentComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with a research item removed
  ScrivenerProject withRemovedResearchItem(String itemId) {
    final newResearchItems = Map<String, ResearchItem>.from(researchItems);
    newResearchItems.remove(itemId);
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: newResearchItems,
      documentComments: documentComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Get research items linked to a specific document
  List<ResearchItem> getLinkedResearchItems(String documentId) {
    return researchItems.values
        .where((item) => item.linkedDocumentIds.contains(documentId))
        .toList();
  }

  /// Get comments for a document
  List<DocumentComment> getComments(String documentId) {
    return documentComments[documentId] ?? [];
  }

  /// Get all comments across the project
  List<DocumentComment> get allComments {
    return documentComments.values.expand((c) => c).toList();
  }

  /// Create a copy with updated comments for a document
  ScrivenerProject withUpdatedComments(
      String documentId, List<DocumentComment> comments) {
    final newComments =
        Map<String, List<DocumentComment>>.from(documentComments);
    newComments[documentId] = comments;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: newComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with a new comment added
  ScrivenerProject withAddedComment(DocumentComment comment) {
    final newComments =
        Map<String, List<DocumentComment>>.from(documentComments);
    final docComments =
        List<DocumentComment>.from(newComments[comment.documentId] ?? []);
    docComments.add(comment);
    newComments[comment.documentId] = docComments;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: newComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with a comment removed
  ScrivenerProject withRemovedComment(String documentId, String commentId) {
    final newComments =
        Map<String, List<DocumentComment>>.from(documentComments);
    final docComments =
        List<DocumentComment>.from(newComments[documentId] ?? []);
    docComments.removeWhere((c) => c.id == commentId);
    newComments[documentId] = docComments;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: newComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Get footnotes for a document
  List<DocumentFootnote> getFootnotes(String documentId) {
    return documentFootnotes[documentId] ?? [];
  }

  /// Get all footnotes across the project
  List<DocumentFootnote> get allFootnotes {
    return documentFootnotes.values.expand((f) => f).toList();
  }

  /// Create a copy with updated footnotes for a document
  ScrivenerProject withUpdatedFootnotes(
      String documentId, List<DocumentFootnote> footnotes) {
    final newFootnotes =
        Map<String, List<DocumentFootnote>>.from(documentFootnotes);
    newFootnotes[documentId] = footnotes;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: documentComments,
      documentFootnotes: newFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with a new footnote added
  ScrivenerProject withAddedFootnote(DocumentFootnote footnote) {
    final newFootnotes =
        Map<String, List<DocumentFootnote>>.from(documentFootnotes);
    final docFootnotes =
        List<DocumentFootnote>.from(newFootnotes[footnote.documentId] ?? []);
    docFootnotes.add(footnote);
    newFootnotes[footnote.documentId] = docFootnotes;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: documentComments,
      documentFootnotes: newFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with a footnote removed
  ScrivenerProject withRemovedFootnote(String documentId, String footnoteId) {
    final newFootnotes =
        Map<String, List<DocumentFootnote>>.from(documentFootnotes);
    final docFootnotes =
        List<DocumentFootnote>.from(newFootnotes[documentId] ?? []);
    docFootnotes.removeWhere((f) => f.id == footnoteId);
    newFootnotes[documentId] = docFootnotes;
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: documentComments,
      documentFootnotes: newFootnotes,
      footnoteSettings: footnoteSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  /// Create a copy with updated footnote settings
  ScrivenerProject withFootnoteSettings(FootnoteSettings newSettings) {
    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      documentMetadata: documentMetadata,
      documentSnapshots: documentSnapshots,
      researchItems: researchItems,
      documentComments: documentComments,
      documentFootnotes: documentFootnotes,
      footnoteSettings: newSettings,
      settings: settings,
      labels: labels,
      statuses: statuses,
    );
  }

  factory ScrivenerProject.empty(String name, String path) {
    // Create initial structure with standard Scrivener folders
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final manuscript = BinderItem(
      id: '${timestamp}_manuscript',
      title: 'Manuscript',
      type: BinderItemType.folder,
      children: [],
    );

    final research = BinderItem(
      id: '${timestamp}_research',
      title: 'Research',
      type: BinderItemType.folder,
      children: [],
    );

    final characters = BinderItem(
      id: '${timestamp}_characters',
      title: 'Characters',
      type: BinderItemType.folder,
      children: [],
    );

    final places = BinderItem(
      id: '${timestamp}_places',
      title: 'Places',
      type: BinderItemType.folder,
      children: [],
    );

    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: [manuscript, research, characters, places],
      textContents: {},
      documentMetadata: {},
      documentSnapshots: {},
      researchItems: {},
      documentComments: {},
      documentFootnotes: {},
      footnoteSettings: const FootnoteSettings(),
      settings: ProjectSettings.defaults(),
      labels: ProjectLabels(),
      statuses: ProjectStatuses(),
    );
  }
}

class BinderItem {
  final String id;
  final String title;
  final BinderItemType type;
  final List<BinderItem> children;
  final String? label;
  final String? status;
  String? textContent;

  BinderItem({
    required this.id,
    required this.title,
    required this.type,
    this.children = const [],
    this.label,
    this.status,
    this.textContent,
  });

  bool get isFolder => type == BinderItemType.folder;
  bool get isDocument => type == BinderItemType.text;
  bool get isResearchItem => type == BinderItemType.image ||
                              type == BinderItemType.pdf ||
                              type == BinderItemType.webArchive;

  /// Create a copy with updated fields
  BinderItem copyWith({
    String? title,
    List<BinderItem>? children,
    String? label,
    String? status,
  }) {
    return BinderItem(
      id: id,
      title: title ?? this.title,
      type: type,
      children: children ?? this.children,
      label: label ?? this.label,
      status: status ?? this.status,
      textContent: textContent,
    );
  }
}

enum BinderItemType {
  folder,
  text,
  image,
  pdf,
  webArchive,
}

class ProjectSettings {
  final bool autoSave;
  final int autoSaveInterval;
  final String defaultTextFormat;

  ProjectSettings({
    required this.autoSave,
    required this.autoSaveInterval,
    required this.defaultTextFormat,
  });

  factory ProjectSettings.defaults() {
    return ProjectSettings(
      autoSave: true,
      autoSaveInterval: 300,
      defaultTextFormat: 'rtf',
    );
  }
}
