import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_project.dart';

class RecentProjectsService extends ChangeNotifier {
  static const String _recentProjectsKey = 'recent_projects';
  static const int _maxRecentProjects = 10;

  List<RecentProject> _recentProjects = [];
  bool _isLoaded = false;

  List<RecentProject> get recentProjects => _recentProjects;
  bool get isLoaded => _isLoaded;

  /// Load recent projects from SharedPreferences
  Future<void> loadRecentProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_recentProjectsKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _recentProjects = jsonList
            .map((json) => RecentProject.fromJson(json))
            .toList()
          ..sort((a, b) => b.lastOpened.compareTo(a.lastOpened));
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('Error loading recent projects: $e');
      _recentProjects = [];
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Add or update a project in the recent list
  Future<void> addRecentProject({
    required String name,
    required String path,
  }) async {
    try {
      // Remove if already exists
      _recentProjects.removeWhere((p) => p.path == path);

      // Add at the beginning with current time
      final newProject = RecentProject(
        name: name,
        path: path,
        lastOpened: DateTime.now(),
      );
      _recentProjects.insert(0, newProject);

      // Limit to max recent projects
      if (_recentProjects.length > _maxRecentProjects) {
        _recentProjects = _recentProjects.take(_maxRecentProjects).toList();
      }

      await _saveRecentProjects();
      notifyListeners();
    } catch (e) {
      print('Error adding recent project: $e');
    }
  }

  /// Remove a project from the recent list
  Future<void> removeRecentProject(String path) async {
    try {
      _recentProjects.removeWhere((p) => p.path == path);
      await _saveRecentProjects();
      notifyListeners();
    } catch (e) {
      print('Error removing recent project: $e');
    }
  }

  /// Clear all recent projects
  Future<void> clearRecentProjects() async {
    try {
      _recentProjects.clear();
      await _saveRecentProjects();
      notifyListeners();
    } catch (e) {
      print('Error clearing recent projects: $e');
    }
  }

  /// Save recent projects to SharedPreferences
  Future<void> _saveRecentProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _recentProjects.map((p) => p.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_recentProjectsKey, jsonString);
    } catch (e) {
      print('Error saving recent projects: $e');
    }
  }

  /// Check if a project path still exists (platform-specific)
  /// For now, we'll keep all projects and let the user handle invalid paths
  /// In the future, could add file system checks here
  Future<bool> projectExists(String path) async {
    // TODO: Implement platform-specific existence checks
    // For now, assume all projects exist
    return true;
  }
}
