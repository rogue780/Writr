import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

/// Service for accessing files through Android Storage Access Framework (SAF)
/// This allows users to access cloud storage (Google Drive, Dropbox, OneDrive)
/// through their installed apps without requiring API keys or OAuth
class StorageAccessService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _lastSelectedPath;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastSelectedPath => _lastSelectedPath;

  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  Future<bool> ensureStoragePermission({String? writableDirectory}) async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }

    if (writableDirectory != null) {
      final canWrite = await _canWriteToDirectory(writableDirectory);
      if (canWrite) {
        return true;
      }
    }

    final manageStatus = await Permission.manageExternalStorage.status;
    if (!manageStatus.isGranted) {
      final requested = await Permission.manageExternalStorage.request();
      if (requested.isGranted) {
        return true;
      }
    }

    final storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      final requested = await Permission.storage.request();
      if (requested.isGranted) {
        return true;
      }
    }

    if (writableDirectory != null) {
      final canWrite = await _canWriteToDirectory(writableDirectory);
      if (canWrite) {
        return true;
      }
    }

    _error = writableDirectory == null
        ? 'Storage permission is required to access project files. Please grant file access in system settings.'
        : 'Unable to write to the selected folder. On Android 11+, enable "All files access" for Writr in system settings, or choose a different folder.';
    notifyListeners();
    return false;
  }

  Future<bool> _canWriteToDirectory(String directoryPath) async {
    try {
      final testFile = File(path.join(directoryPath, '.writr_write_test'));
      await testFile.writeAsString('test', flush: true);
      await testFile.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Pick a project directory using the system file picker.
  /// Supports both .scriv (Scrivener) and .writ (Writr) project folders.
  /// This works with any storage provider that has a document provider:
  /// - Google Drive
  /// - Dropbox
  /// - OneDrive
  /// - Local storage
  /// - Any other cloud storage app
  Future<String?> pickProject() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use directory picker to select project folder
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Project Folder (.scriv or .writ)',
      );

      if (selectedDirectory == null) {
        // User cancelled
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Verify it's a supported project directory
      final isScrivener = selectedDirectory.endsWith('.scriv');
      final isWritr = selectedDirectory.endsWith('.writ');
      if (!isScrivener && !isWritr) {
        throw Exception(
          'Please select a .scriv or .writ project folder. Selected: $selectedDirectory',
        );
      }

      final hasPermission = await ensureStoragePermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _lastSelectedPath = selectedDirectory;
      _isLoading = false;
      notifyListeners();
      return selectedDirectory;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Pick a Scrivener project directory using the system file picker.
  /// @deprecated Use [pickProject] instead, which supports both .scriv and .writ formats.
  Future<String?> pickScrivenerProject() => pickProject();

  /// Pick any directory for creating a new project
  Future<String?> pickDirectoryForNewProject() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder for new project',
      );

      if (selectedDirectory == null) {
        // User cancelled
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final hasPermission = await ensureStoragePermission(
        writableDirectory: selectedDirectory,
      );
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _lastSelectedPath = selectedDirectory;
      _isLoading = false;
      notifyListeners();
      return selectedDirectory;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Copy a project from cloud storage to local cache for better performance
  /// This is optional but recommended for editing
  Future<String?> copyProjectToCache(String sourcePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await ensureStoragePermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final cacheDir = await getApplicationCacheDirectory();
      final projectName = path.basename(sourcePath);
      final cachedPath = path.join(cacheDir.path, projectName);

      // Create cache directory
      final cachedDir = Directory(cachedPath);
      if (await cachedDir.exists()) {
        await cachedDir.delete(recursive: true);
      }
      await cachedDir.create(recursive: true);

      // Copy project recursively
      await _copyDirectory(Directory(sourcePath), cachedDir);

      _isLoading = false;
      notifyListeners();
      return cachedPath;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Sync changes back to the original location
  Future<bool> syncProjectBack(String cachedPath, String originalPath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await ensureStoragePermission(
        writableDirectory: originalPath,
      );
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Delete original directory contents
      final originalDir = Directory(originalPath);
      if (await originalDir.exists()) {
        await for (final entity in originalDir.list()) {
          await entity.delete(recursive: true);
        }
      } else {
        await originalDir.create(recursive: true);
      }

      // Copy from cache back to original
      await _copyDirectory(Directory(cachedPath), originalDir);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Recursively copy directory contents
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(
          path.join(destination.path, path.basename(entity.path)),
        );
        await newDirectory.create(recursive: true);
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(
          path.join(destination.path, path.basename(entity.path)),
        );
        await entity.copy(newFile.path);
      }
    }
  }

  /// Get available storage locations (shows installed cloud apps)
  /// Note: This is handled by the Android file picker automatically
  Future<void> showFilePicker() async {
    // The file picker will automatically show all available
    // document providers including:
    // - Google Drive
    // - Dropbox
    // - OneDrive
    // - Local storage
    // - Any other installed cloud storage apps
    await pickScrivenerProject();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
