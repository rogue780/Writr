import '../models/cloud_file.dart';

/// Base interface for cloud storage providers
abstract class CloudStorageProvider {
  /// Name of the provider (e.g., "Google Drive", "Dropbox")
  String get providerName;

  /// Whether the provider is currently authenticated
  bool get isAuthenticated;

  /// Sign in to the cloud provider
  Future<bool> signIn();

  /// Sign out from the cloud provider
  Future<void> signOut();

  /// List files and folders in the given directory
  /// If [folderId] is null, lists root directory
  Future<List<CloudFile>> listFiles({String? folderId});

  /// Get file content as bytes
  Future<List<int>> downloadFile(String fileId);

  /// Upload file content
  Future<CloudFile> uploadFile({
    required String name,
    required List<int> content,
    String? parentFolderId,
    String? mimeType,
  });

  /// Create a folder
  Future<CloudFile> createFolder({
    required String name,
    String? parentFolderId,
  });

  /// Delete a file or folder
  Future<void> delete(String fileId);

  /// Search for files/folders by name
  Future<List<CloudFile>> search(String query);

  /// Get a specific file by ID
  Future<CloudFile> getFile(String fileId);
}
