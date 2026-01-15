import 'package:flutter/foundation.dart';
import '../models/cloud_file.dart';
import 'cloud_storage_provider.dart';
import 'google_drive_provider.dart';
import 'dropbox_provider.dart';
import 'onedrive_provider.dart';

enum CloudProvider { googleDrive, dropbox, oneDrive }

class CloudStorageService extends ChangeNotifier {
  CloudStorageProvider? _currentProvider;
  CloudProvider? _currentProviderType;
  bool _isLoading = false;
  String? _error;

  CloudStorageProvider? get currentProvider => _currentProvider;
  CloudProvider? get currentProviderType => _currentProviderType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated =>
      _currentProvider?.isAuthenticated ?? false;

  /// Select and sign in to a cloud provider
  Future<bool> selectProvider(CloudProvider provider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create provider instance
      switch (provider) {
        case CloudProvider.googleDrive:
          _currentProvider = GoogleDriveProvider();
          break;
        case CloudProvider.dropbox:
          _currentProvider = DropboxProvider();
          break;
        case CloudProvider.oneDrive:
          _currentProvider = OneDriveProvider();
          break;
      }

      // Attempt sign in
      final success = await _currentProvider!.signIn();

      if (success) {
        _currentProviderType = provider;
      } else {
        _currentProvider = null;
        _error = 'Sign in cancelled or failed';
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _currentProvider = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out from current provider
  Future<void> signOut() async {
    if (_currentProvider == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _currentProvider!.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _currentProvider = null;
      _currentProviderType = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// List files in the current directory
  Future<List<CloudFile>> listFiles({String? folderId}) async {
    if (_currentProvider == null) {
      throw Exception('No provider selected');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final files = await _currentProvider!.listFiles(folderId: folderId);
      _isLoading = false;
      notifyListeners();
      return files;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Download a file
  Future<List<int>> downloadFile(String fileId) async {
    if (_currentProvider == null) {
      throw Exception('No provider selected');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final content = await _currentProvider!.downloadFile(fileId);
      _isLoading = false;
      notifyListeners();
      return content;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Upload a file
  Future<CloudFile> uploadFile({
    required String name,
    required List<int> content,
    String? parentFolderId,
    String? mimeType,
  }) async {
    if (_currentProvider == null) {
      throw Exception('No provider selected');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final file = await _currentProvider!.uploadFile(
        name: name,
        content: content,
        parentFolderId: parentFolderId,
        mimeType: mimeType,
      );
      _isLoading = false;
      notifyListeners();
      return file;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create a folder
  Future<CloudFile> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    if (_currentProvider == null) {
      throw Exception('No provider selected');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final folder = await _currentProvider!.createFolder(
        name: name,
        parentFolderId: parentFolderId,
      );
      _isLoading = false;
      notifyListeners();
      return folder;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a file or folder
  Future<void> delete(String fileId) async {
    if (_currentProvider == null) {
      throw Exception('No provider selected');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _currentProvider!.delete(fileId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Search for files
  Future<List<CloudFile>> search(String query) async {
    if (_currentProvider == null) {
      throw Exception('No provider selected');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _currentProvider!.search(query);
      _isLoading = false;
      notifyListeners();
      return results;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get a specific file
  Future<CloudFile> getFile(String fileId) async {
    if (_currentProvider == null) {
      throw Exception('No provider selected');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final file = await _currentProvider!.getFile(fileId);
      _isLoading = false;
      notifyListeners();
      return file;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
