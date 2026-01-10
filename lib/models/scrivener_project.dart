class ScrivenerProject {
  final String name;
  final String path;
  final List<BinderItem> binderItems;
  final Map<String, String> textContents; // ID -> content
  final ProjectSettings settings;

  ScrivenerProject({
    required this.name,
    required this.path,
    required this.binderItems,
    required this.textContents,
    required this.settings,
  });

  factory ScrivenerProject.empty(String name, String path) {
    // Create initial structure with Manuscript folder
    final manuscriptId = DateTime.now().millisecondsSinceEpoch.toString();
    final manuscript = BinderItem(
      id: manuscriptId,
      title: 'Manuscript',
      type: BinderItemType.folder,
      children: [],
    );

    return ScrivenerProject(
      name: name,
      path: path,
      binderItems: [manuscript],
      textContents: {},
      settings: ProjectSettings.defaults(),
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
