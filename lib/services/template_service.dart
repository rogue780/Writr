import 'package:flutter/material.dart';
import '../models/template.dart';
import '../models/scrivener_project.dart';

/// Service for managing document and project templates
class TemplateService extends ChangeNotifier {
  /// Document templates
  final List<DocumentTemplate> _documentTemplates = [];

  /// Project templates
  final List<ProjectTemplate> _projectTemplates = [];

  /// Get all document templates
  List<DocumentTemplate> get documentTemplates =>
      List.unmodifiable(_documentTemplates);

  /// Get all project templates
  List<ProjectTemplate> get projectTemplates =>
      List.unmodifiable(_projectTemplates);

  /// Get document templates by type
  List<DocumentTemplate> getDocumentTemplatesByType(DocumentTemplateType type) {
    return _documentTemplates.where((t) => t.type == type).toList();
  }

  /// Get project templates by type
  List<ProjectTemplate> getProjectTemplatesByType(ProjectTemplateType type) {
    return _projectTemplates.where((t) => t.type == type).toList();
  }

  /// Initialize with built-in templates
  void initializeBuiltInTemplates() {
    _initializeBuiltInDocumentTemplates();
    _initializeBuiltInProjectTemplates();
    notifyListeners();
  }

  void _initializeBuiltInDocumentTemplates() {
    final builtInTemplates = [
      // Chapter template
      DocumentTemplate(
        id: 'builtin_chapter',
        name: 'Chapter',
        description: 'Standard chapter template with title and content area',
        content: '''# Chapter [Number]: [Title]

## Summary
[Brief summary of what happens in this chapter]

---

[Chapter content goes here...]
''',
        type: DocumentTemplateType.chapter,
        icon: Icons.menu_book,
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Scene template
      DocumentTemplate(
        id: 'builtin_scene',
        name: 'Scene',
        description: 'Scene template with POV, setting, and goal tracking',
        content: '''## Scene: [Title]

**POV Character:** [Name]
**Setting:** [Location, Time]
**Scene Goal:** [What the POV character wants]

---

[Scene content goes here...]

---

**Scene Notes:**
- Conflict:
- Outcome:
- Sequel Hook:
''',
        type: DocumentTemplateType.scene,
        icon: Icons.movie,
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Character sheet
      DocumentTemplate(
        id: 'builtin_character',
        name: 'Character Sheet',
        description: 'Detailed character profile template',
        content: '''# Character Profile: [Name]

## Basic Information
- **Full Name:**
- **Nickname(s):**
- **Age:**
- **Gender:**
- **Occupation:**

## Physical Description
- **Height:**
- **Build:**
- **Hair:**
- **Eyes:**
- **Distinguishing Features:**

## Personality
- **Traits:**
- **Strengths:**
- **Weaknesses:**
- **Fears:**
- **Desires:**

## Background
- **Birthplace:**
- **Family:**
- **Education:**
- **Significant Events:**

## Story Role
- **Goal:**
- **Motivation:**
- **Conflict:**
- **Arc:**

## Relationships
[List important relationships with other characters]

## Notes
[Additional notes about this character]
''',
        type: DocumentTemplateType.character,
        icon: Icons.person,
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Location template
      DocumentTemplate(
        id: 'builtin_location',
        name: 'Location',
        description: 'Template for describing settings and locations',
        content: '''# Location: [Name]

## Overview
[Brief description of this location]

## Physical Description
- **Type:** [City, Building, Natural, etc.]
- **Size:**
- **Climate/Weather:**
- **Notable Features:**

## Atmosphere
- **Mood:**
- **Sounds:**
- **Smells:**
- **Lighting:**

## History
[Relevant historical information]

## Inhabitants
[Who lives or works here]

## Story Significance
[How this location relates to the plot]

## Related Locations
[Nearby or connected locations]

## Notes
[Additional details]
''',
        type: DocumentTemplateType.location,
        icon: Icons.place,
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // World building template
      DocumentTemplate(
        id: 'builtin_worldbuilding',
        name: 'World Building',
        description: 'Template for world and setting details',
        content: '''# World Building: [Topic]

## Overview
[General description]

## Key Details

### History
[Historical background]

### Culture
[Cultural aspects]

### Politics/Government
[Political structure]

### Economy
[Economic system]

### Technology/Magic
[Technological or magical elements]

### Religion/Beliefs
[Religious or philosophical systems]

## Impact on Story
[How this affects the narrative]

## Visual References
[Description of visual elements or inspirations]

## Notes
[Additional details]
''',
        type: DocumentTemplateType.worldBuilding,
        icon: Icons.public,
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Outline template
      DocumentTemplate(
        id: 'builtin_outline',
        name: 'Story Outline',
        description: 'Three-act structure outline template',
        content: '''# Story Outline: [Title]

## Premise
[One-sentence summary of the story]

## Theme
[Central theme or message]

---

## Act 1: Setup (25%)

### Opening Scene
[How the story begins]

### Inciting Incident
[Event that disrupts the protagonist's world]

### First Plot Point
[Decision that launches the main story]

---

## Act 2: Confrontation (50%)

### Rising Action
[Escalating challenges and obstacles]

### Midpoint
[Major revelation or shift]

### Dark Moment
[Protagonist's lowest point]

---

## Act 3: Resolution (25%)

### Climax
[Final confrontation]

### Resolution
[How conflicts are resolved]

### Ending
[Final image or scene]

---

## Subplots
1. [Subplot 1]
2. [Subplot 2]

## Notes
[Additional planning notes]
''',
        type: DocumentTemplateType.outline,
        icon: Icons.format_list_numbered,
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Research notes template
      DocumentTemplate(
        id: 'builtin_research',
        name: 'Research Notes',
        description: 'Template for organizing research',
        content: '''# Research: [Topic]

## Summary
[Brief overview of the topic]

## Key Facts
-
-
-

## Sources
1. [Source 1]
2. [Source 2]

## Quotes
> "[Notable quote]"
> — Source

## How This Applies to Story
[Relevance to your writing]

## Follow-up Questions
- [ ]
- [ ]

## Notes
[Additional observations]
''',
        type: DocumentTemplateType.research,
        icon: Icons.science,
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    for (final template in builtInTemplates) {
      if (!_documentTemplates.any((t) => t.id == template.id)) {
        _documentTemplates.add(template);
      }
    }
  }

  void _initializeBuiltInProjectTemplates() {
    final builtInTemplates = [
      // Blank project
      ProjectTemplate(
        id: 'builtin_blank',
        name: 'Blank Project',
        description: 'Start with a clean slate',
        type: ProjectTemplateType.blank,
        folders: const [
          TemplateFolder(name: 'Manuscript'),
          TemplateFolder(name: 'Research'),
          TemplateFolder(name: 'Characters'),
          TemplateFolder(name: 'Places'),
        ],
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Novel template
      ProjectTemplate(
        id: 'builtin_novel',
        name: 'Novel',
        description: 'Complete novel structure with chapters, characters, and world building',
        type: ProjectTemplateType.novel,
        folders: const [
          TemplateFolder(
            name: 'Manuscript',
            subfolders: [
              TemplateFolder(
                name: 'Part 1',
                documents: [
                  TemplateDocument(name: 'Chapter 1', type: DocumentTemplateType.chapter),
                  TemplateDocument(name: 'Chapter 2', type: DocumentTemplateType.chapter),
                  TemplateDocument(name: 'Chapter 3', type: DocumentTemplateType.chapter),
                ],
              ),
              TemplateFolder(
                name: 'Part 2',
                documents: [
                  TemplateDocument(name: 'Chapter 4', type: DocumentTemplateType.chapter),
                  TemplateDocument(name: 'Chapter 5', type: DocumentTemplateType.chapter),
                  TemplateDocument(name: 'Chapter 6', type: DocumentTemplateType.chapter),
                ],
              ),
              TemplateFolder(
                name: 'Part 3',
                documents: [
                  TemplateDocument(name: 'Chapter 7', type: DocumentTemplateType.chapter),
                  TemplateDocument(name: 'Chapter 8', type: DocumentTemplateType.chapter),
                  TemplateDocument(name: 'Chapter 9', type: DocumentTemplateType.chapter),
                ],
              ),
            ],
          ),
          TemplateFolder(
            name: 'Characters',
            documents: [
              TemplateDocument(name: 'Protagonist', type: DocumentTemplateType.character),
              TemplateDocument(name: 'Antagonist', type: DocumentTemplateType.character),
              TemplateDocument(name: 'Supporting Cast', type: DocumentTemplateType.notes),
            ],
          ),
          TemplateFolder(
            name: 'World Building',
            documents: [
              TemplateDocument(name: 'Setting Overview', type: DocumentTemplateType.worldBuilding),
              TemplateDocument(name: 'History', type: DocumentTemplateType.worldBuilding),
              TemplateDocument(name: 'Culture', type: DocumentTemplateType.worldBuilding),
            ],
          ),
          TemplateFolder(
            name: 'Locations',
            documents: [
              TemplateDocument(name: 'Main Location', type: DocumentTemplateType.location),
            ],
          ),
          TemplateFolder(
            name: 'Planning',
            documents: [
              TemplateDocument(name: 'Story Outline', type: DocumentTemplateType.outline),
              TemplateDocument(name: 'Timeline', type: DocumentTemplateType.notes),
              TemplateDocument(name: 'Plot Notes', type: DocumentTemplateType.notes),
            ],
          ),
          TemplateFolder(name: 'Research'),
        ],
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Short story template
      ProjectTemplate(
        id: 'builtin_shortstory',
        name: 'Short Story',
        description: 'Compact structure for short fiction',
        type: ProjectTemplateType.shortStory,
        folders: const [
          TemplateFolder(
            name: 'Manuscript',
            documents: [
              TemplateDocument(name: 'Opening', type: DocumentTemplateType.scene),
              TemplateDocument(name: 'Middle', type: DocumentTemplateType.scene),
              TemplateDocument(name: 'Climax', type: DocumentTemplateType.scene),
              TemplateDocument(name: 'Resolution', type: DocumentTemplateType.scene),
            ],
          ),
          TemplateFolder(
            name: 'Planning',
            documents: [
              TemplateDocument(name: 'Outline', type: DocumentTemplateType.outline),
              TemplateDocument(name: 'Character Notes', type: DocumentTemplateType.character),
            ],
          ),
          TemplateFolder(name: 'Research'),
        ],
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Non-fiction template
      ProjectTemplate(
        id: 'builtin_nonfiction',
        name: 'Non-Fiction',
        description: 'Organized structure for non-fiction writing',
        type: ProjectTemplateType.nonFiction,
        folders: const [
          TemplateFolder(
            name: 'Manuscript',
            subfolders: [
              TemplateFolder(
                name: 'Front Matter',
                documents: [
                  TemplateDocument(name: 'Title Page'),
                  TemplateDocument(name: 'Table of Contents'),
                  TemplateDocument(name: 'Introduction'),
                ],
              ),
              TemplateFolder(
                name: 'Main Content',
                documents: [
                  TemplateDocument(name: 'Chapter 1'),
                  TemplateDocument(name: 'Chapter 2'),
                  TemplateDocument(name: 'Chapter 3'),
                ],
              ),
              TemplateFolder(
                name: 'Back Matter',
                documents: [
                  TemplateDocument(name: 'Conclusion'),
                  TemplateDocument(name: 'Bibliography'),
                  TemplateDocument(name: 'Index'),
                ],
              ),
            ],
          ),
          TemplateFolder(
            name: 'Research',
            documents: [
              TemplateDocument(name: 'Sources', type: DocumentTemplateType.research),
              TemplateDocument(name: 'Notes', type: DocumentTemplateType.notes),
            ],
          ),
          TemplateFolder(
            name: 'Planning',
            documents: [
              TemplateDocument(name: 'Outline', type: DocumentTemplateType.outline),
              TemplateDocument(name: 'Target Audience'),
            ],
          ),
        ],
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Thesis template
      ProjectTemplate(
        id: 'builtin_thesis',
        name: 'Thesis',
        description: 'Academic thesis or dissertation format',
        type: ProjectTemplateType.thesis,
        folders: const [
          TemplateFolder(
            name: 'Manuscript',
            subfolders: [
              TemplateFolder(
                name: 'Preliminary Pages',
                documents: [
                  TemplateDocument(name: 'Title Page'),
                  TemplateDocument(name: 'Abstract'),
                  TemplateDocument(name: 'Acknowledgments'),
                  TemplateDocument(name: 'Table of Contents'),
                  TemplateDocument(name: 'List of Figures'),
                  TemplateDocument(name: 'List of Tables'),
                ],
              ),
              TemplateFolder(
                name: 'Body',
                documents: [
                  TemplateDocument(name: 'Chapter 1: Introduction'),
                  TemplateDocument(name: 'Chapter 2: Literature Review'),
                  TemplateDocument(name: 'Chapter 3: Methodology'),
                  TemplateDocument(name: 'Chapter 4: Results'),
                  TemplateDocument(name: 'Chapter 5: Discussion'),
                  TemplateDocument(name: 'Chapter 6: Conclusion'),
                ],
              ),
              TemplateFolder(
                name: 'End Matter',
                documents: [
                  TemplateDocument(name: 'References'),
                  TemplateDocument(name: 'Appendices'),
                ],
              ),
            ],
          ),
          TemplateFolder(
            name: 'Research',
            documents: [
              TemplateDocument(name: 'Literature Notes', type: DocumentTemplateType.research),
              TemplateDocument(name: 'Data', type: DocumentTemplateType.research),
              TemplateDocument(name: 'Analysis Notes', type: DocumentTemplateType.notes),
            ],
          ),
          TemplateFolder(
            name: 'Planning',
            documents: [
              TemplateDocument(name: 'Research Questions'),
              TemplateDocument(name: 'Timeline'),
              TemplateDocument(name: 'Advisor Feedback'),
            ],
          ),
        ],
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),

      // Blog template
      ProjectTemplate(
        id: 'builtin_blog',
        name: 'Blog',
        description: 'Simple structure for blog posts',
        type: ProjectTemplateType.blog,
        folders: const [
          TemplateFolder(
            name: 'Published',
          ),
          TemplateFolder(
            name: 'Drafts',
            documents: [
              TemplateDocument(name: 'New Post'),
            ],
          ),
          TemplateFolder(
            name: 'Ideas',
            documents: [
              TemplateDocument(name: 'Post Ideas'),
            ],
          ),
          TemplateFolder(name: 'Research'),
        ],
        isBuiltIn: true,
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    for (final template in builtInTemplates) {
      if (!_projectTemplates.any((t) => t.id == template.id)) {
        _projectTemplates.add(template);
      }
    }
  }

  /// Add a custom document template
  void addDocumentTemplate(DocumentTemplate template) {
    _documentTemplates.add(template);
    notifyListeners();
  }

  /// Update a document template
  void updateDocumentTemplate(DocumentTemplate template) {
    final index = _documentTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _documentTemplates[index] = template;
      notifyListeners();
    }
  }

  /// Delete a document template
  void deleteDocumentTemplate(String templateId) {
    _documentTemplates.removeWhere((t) => t.id == templateId && !t.isBuiltIn);
    notifyListeners();
  }

  /// Add a custom project template
  void addProjectTemplate(ProjectTemplate template) {
    _projectTemplates.add(template);
    notifyListeners();
  }

  /// Delete a project template
  void deleteProjectTemplate(String templateId) {
    _projectTemplates.removeWhere((t) => t.id == templateId && !t.isBuiltIn);
    notifyListeners();
  }

  /// Create a document from a template
  String getDocumentContent(String templateId) {
    final template = _documentTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found'),
    );
    return template.content;
  }

  /// Create a new project from a template
  ScrivenerProject createProjectFromTemplate({
    required String name,
    required String path,
    required String templateId,
  }) {
    final template = _projectTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw Exception('Template not found'),
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final binderItems = <BinderItem>[];
    final textContents = <String, String>{};

    // Convert template folders to binder items
    for (int i = 0; i < template.folders.length; i++) {
      final folder = template.folders[i];
      final folderId = '${timestamp}_folder_$i';
      final folderItem = _createBinderItemFromFolder(
        folder,
        folderId,
        textContents,
        template.documentTemplates,
      );
      binderItems.add(folderItem);
    }

    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: binderItems,
      textContents: textContents,
      settings: ProjectSettings.defaults(),
    );
  }

  BinderItem _createBinderItemFromFolder(
    TemplateFolder folder,
    String parentId,
    Map<String, String> textContents,
    List<DocumentTemplate> docTemplates,
  ) {
    final children = <BinderItem>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Add subfolders
    for (int i = 0; i < folder.subfolders.length; i++) {
      final subfolder = folder.subfolders[i];
      final subfolderId = '${parentId}_sub_$i';
      children.add(_createBinderItemFromFolder(
        subfolder,
        subfolderId,
        textContents,
        docTemplates,
      ));
    }

    // Add documents
    for (int i = 0; i < folder.documents.length; i++) {
      final doc = folder.documents[i];
      final docId = '${parentId}_doc_$i';

      // Get content from document template if available
      String content = doc.content;
      if (content.isEmpty) {
        final matchingTemplate = docTemplates.firstWhere(
          (t) => t.type == doc.type,
          orElse: () => _documentTemplates.firstWhere(
            (t) => t.type == doc.type,
            orElse: () => DocumentTemplate(
              id: 'empty',
              name: 'Empty',
              description: '',
              content: '',
              type: DocumentTemplateType.general,
              createdAt: DateTime.now(),
            ),
          ),
        );
        content = matchingTemplate.content;
      }

      textContents[docId] = content;
      children.add(BinderItem(
        id: docId,
        title: doc.name,
        type: BinderItemType.text,
      ));
    }

    return BinderItem(
      id: '${timestamp}_${folder.name.toLowerCase().replaceAll(' ', '_')}',
      title: folder.name,
      type: BinderItemType.folder,
      children: children,
    );
  }

  /// Create a document template from an existing document
  DocumentTemplate createTemplateFromDocument({
    required String name,
    required String description,
    required String content,
    required DocumentTemplateType type,
  }) {
    final template = DocumentTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      content: content,
      type: type,
      icon: type.icon,
      isBuiltIn: false,
      createdAt: DateTime.now(),
    );

    addDocumentTemplate(template);
    return template;
  }

  /// Load templates from JSON
  void loadTemplates(Map<String, dynamic> data) {
    // Load document templates
    if (data['documentTemplates'] != null) {
      for (final templateJson in data['documentTemplates'] as List) {
        final template =
            DocumentTemplate.fromJson(templateJson as Map<String, dynamic>);
        if (!_documentTemplates.any((t) => t.id == template.id)) {
          _documentTemplates.add(template);
        }
      }
    }

    // Load project templates
    if (data['projectTemplates'] != null) {
      for (final templateJson in data['projectTemplates'] as List) {
        final template =
            ProjectTemplate.fromJson(templateJson as Map<String, dynamic>);
        if (!_projectTemplates.any((t) => t.id == template.id)) {
          _projectTemplates.add(template);
        }
      }
    }

    notifyListeners();
  }

  /// Export templates to JSON
  Map<String, dynamic> toJson() {
    return {
      'documentTemplates': _documentTemplates
          .where((t) => !t.isBuiltIn)
          .map((t) => t.toJson())
          .toList(),
      'projectTemplates': _projectTemplates
          .where((t) => !t.isBuiltIn)
          .map((t) => t.toJson())
          .toList(),
    };
  }
}
