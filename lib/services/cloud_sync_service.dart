import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/cloud_file.dart';
import 'cloud_storage_service.dart';

/// Service for syncing Scrivener projects with cloud storage
class CloudSyncService extends ChangeNotifier {
  final CloudStorageService _cloudStorageService;

  CloudSyncService(this._cloudStorageService);

  bool _isSyncing = false;
  double _syncProgress = 0.0;
  String? _syncStatus;
  String? _error;

  bool get isSyncing => _isSyncing;
  double get syncProgress => _syncProgress;
  String? get syncStatus => _syncStatus;
  String? get error => _error;

  /// Download a Scrivener project from cloud storage
  /// Returns the local path where the project was downloaded
  Future<String?> downloadProject(CloudFile projectFolder) async {
    if (!projectFolder.isScrivenerProject) {
      _error = 'Selected file is not a Scrivener project';
      notifyListeners();
      return null;
    }

    _isSyncing = true;
    _syncProgress = 0.0;
    _syncStatus = 'Downloading project...';
    _error = null;
    notifyListeners();

    try {
      // Get local directory for storing projects
      final localDir = await _getLocalProjectsDirectory();
      final projectDir = Directory(path.join(localDir.path, projectFolder.name));

      // Create project directory
      if (await projectDir.exists()) {
        await projectDir.delete(recursive: true);
      }
      await projectDir.create(recursive: true);

      // Download all files from the cloud project
      await _downloadFolderRecursively(
        projectFolder.id,
        projectDir.path,
      );

      _isSyncing = false;
      _syncProgress = 1.0;
      _syncStatus = 'Download complete';
      notifyListeners();

      return projectDir.path;
    } catch (e) {
      _error = 'Failed to download project: $e';
      _isSyncing = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload a Scrivener project to cloud storage
  Future<bool> uploadProject(
    String localProjectPath,
    String? cloudParentFolderId,
  ) async {
    _isSyncing = true;
    _syncProgress = 0.0;
    _syncStatus = 'Uploading project...';
    _error = null;
    notifyListeners();

    try {
      final projectDir = Directory(localProjectPath);
      if (!await projectDir.exists()) {
        throw Exception('Project directory does not exist');
      }

      final projectName = path.basename(localProjectPath);

      // Create project folder in cloud if it doesn't exist
      CloudFile? cloudProjectFolder;
      try {
        cloudProjectFolder = await _cloudStorageService.createFolder(
          name: projectName,
          parentFolderId: cloudParentFolderId,
        );
      } catch (e) {
        // Folder might already exist, try to find it
        final files = await _cloudStorageService.listFiles(
          folderId: cloudParentFolderId,
        );
        cloudProjectFolder = files.firstWhere(
          (f) => f.name == projectName && f.isDirectory,
          orElse: () => throw Exception('Failed to create/find project folder'),
        );
      }

      // Upload all files recursively
      await _uploadFolderRecursively(
        projectDir.path,
        cloudProjectFolder.id,
      );

      _isSyncing = false;
      _syncProgress = 1.0;
      _syncStatus = 'Upload complete';
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to upload project: $e';
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Download a folder and its contents recursively
  Future<void> _downloadFolderRecursively(
    String cloudFolderId,
    String localPath,
  ) async {
    // List files in cloud folder
    final files = await _cloudStorageService.listFiles(folderId: cloudFolderId);

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final localFilePath = path.join(localPath, file.name);

      if (file.isDirectory) {
        // Create local directory and download recursively
        final dir = Directory(localFilePath);
        await dir.create(recursive: true);
        await _downloadFolderRecursively(file.id, localFilePath);
      } else {
        // Download file
        final content = await _cloudStorageService.downloadFile(file.id);
        final localFile = File(localFilePath);
        await localFile.writeAsBytes(content);
      }

      // Update progress
      _syncProgress = (i + 1) / files.length * 0.5; // First half of progress
      notifyListeners();
    }
  }

  /// Upload a folder and its contents recursively
  Future<void> _uploadFolderRecursively(
    String localPath,
    String cloudFolderId,
  ) async {
    final dir = Directory(localPath);
    final entities = await dir.list().toList();

    for (int i = 0; i < entities.length; i++) {
      final entity = entities[i];
      final name = path.basename(entity.path);

      if (entity is Directory) {
        // Create cloud folder and upload recursively
        final cloudFolder = await _cloudStorageService.createFolder(
          name: name,
          parentFolderId: cloudFolderId,
        );
        await _uploadFolderRecursively(entity.path, cloudFolder.id);
      } else if (entity is File) {
        // Upload file
        final content = await entity.readAsBytes();
        await _cloudStorageService.uploadFile(
          name: name,
          content: content,
          parentFolderId: cloudFolderId,
        );
      }

      // Update progress
      _syncProgress = 0.5 + (i + 1) / entities.length * 0.5; // Second half
      notifyListeners();
    }
  }

  /// Get local directory for storing downloaded projects
  Future<Directory> _getLocalProjectsDirectory() async {
    if (kIsWeb) {
      // For web, we can't use file system, would need IndexedDB
      // For now, throw an error
      throw UnsupportedError(
        'Web platform requires different storage strategy',
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    final projectsDir = Directory(path.join(appDir.path, 'CloudProjects'));

    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }

    return projectsDir;
  }

  /// Sync local changes back to cloud
  Future<bool> syncChanges(String localProjectPath, String cloudProjectId) async {
    _isSyncing = true;
    _syncStatus = 'Syncing changes...';
    notifyListeners();

    try {
      // For now, just re-upload the entire project
      // In the future, could implement delta sync
      await uploadProject(localProjectPath, null);
      return true;
    } catch (e) {
      _error = 'Failed to sync changes: $e';
      notifyListeners();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
