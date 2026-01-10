import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/cloud_storage.dart';
import 'cloud/google_drive_provider.dart';
import 'cloud/dropbox_provider.dart';
import 'cloud/onedrive_provider.dart';

abstract class CloudProviderInterface {
  Future<void> authenticate();
  Future<void> signOut();
  Future<List<CloudFile>> listFiles(String? parentId);
  Future<String> downloadFile(String fileId, String localPath);
  Future<void> uploadFile(String localPath, String? parentId);
  Future<void> deleteFile(String fileId);
  bool get isAuthenticated;
}

class CloudStorageService extends ChangeNotifier {
  final Map<CloudProvider, CloudProviderInterface> _providers = {};
  CloudProvider? _currentProvider;
  List<CloudFile> _files = [];
  bool _isLoading = false;
  String? _error;

  CloudProvider? get currentProvider => _currentProvider;
  List<CloudFile> get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CloudStorageService() {
    _initializeProviders();
  }

  void _initializeProviders() {
    _providers[CloudProvider.googleDrive] = GoogleDriveProvider();
    _providers[CloudProvider.dropbox] = DropboxProvider();
    _providers[CloudProvider.oneDrive] = OneDriveProvider();
  }

  /// Set the current cloud provider
  void setProvider(CloudProvider provider) {
    _currentProvider = provider;
    notifyListeners();
  }

  /// Authenticate with the current provider
  Future<void> authenticate() async {
    if (_currentProvider == null) {
      _error = 'No cloud provider selected';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final provider = _providers[_currentProvider]!;
      await provider.authenticate();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out from the current provider
  Future<void> signOut() async {
    if (_currentProvider == null) return;

    try {
      final provider = _providers[_currentProvider]!;
      await provider.signOut();
      _files = [];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// List files from the current provider
  Future<void> listFiles({String? parentId}) async {
    if (_currentProvider == null) {
      _error = 'No cloud provider selected';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final provider = _providers[_currentProvider]!;
      _files = await provider.listFiles(parentId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Download a file from cloud storage
  Future<String?> downloadFile(String fileId, String localPath) async {
    if (_currentProvider == null) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final provider = _providers[_currentProvider]!;
      final downloadedPath = await provider.downloadFile(fileId, localPath);
      _isLoading = false;
      notifyListeners();
      return downloadedPath;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Upload a file to cloud storage
  Future<void> uploadFile(String localPath, {String? parentId}) async {
    if (_currentProvider == null) {
      _error = 'No cloud provider selected';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final provider = _providers[_currentProvider]!;
      await provider.uploadFile(localPath, parentId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a file from cloud storage
  Future<void> deleteFile(String fileId) async {
    if (_currentProvider == null) return;

    try {
      final provider = _providers[_currentProvider]!;
      await provider.deleteFile(fileId);
      await listFiles();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Check if current provider is authenticated
  bool get isAuthenticated {
    if (_currentProvider == null) return false;
    final provider = _providers[_currentProvider];
    return provider?.isAuthenticated ?? false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
