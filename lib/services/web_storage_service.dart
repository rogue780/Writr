import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scrivener_project.dart';

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
      final jsonString = json.encode(_projects);
      await prefs.setString(_projectsKey, jsonString);

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
        'defaultZoom': project.settings.defaultZoom,
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
        defaultZoom: json['settings']['defaultZoom'],
      ),
    );
  }

  /// Convert BinderItem to JSON
  Map<String, dynamic> _binderItemToJson(BinderItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'type': item.type.toString(),
      'children': item.children.map((child) => _binderItemToJson(child)).toList(),
    };
  }

  /// Convert JSON to BinderItem
  BinderItem _binderItemFromJson(Map<String, dynamic> json) {
    return BinderItem(
      id: json['id'],
      title: json['title'],
      type: _parseBinderItemType(json['type']),
      children: (json['children'] as List)
          .map((child) => _binderItemFromJson(child))
          .toList(),
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

  /// Clear all error state
  void clearError() {
    notifyListeners();
  }
}
