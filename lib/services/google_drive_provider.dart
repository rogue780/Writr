import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../models/cloud_file.dart';
import 'cloud_storage_provider.dart';

class GoogleDriveProvider implements CloudStorageProvider {
  static const _scopes = [drive.DriveApi.driveFileScope];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  @override
  String get providerName => 'Google Drive';

  @override
  bool get isAuthenticated => _currentUser != null && _driveApi != null;

  @override
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
      }

      _currentUser = account;
      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);

      return true;
    } catch (e) {
      print('Google Drive sign-in error: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  @override
  Future<List<CloudFile>> listFiles({String? folderId}) async {
    if (_driveApi == null) throw Exception('Not authenticated');

    final query = folderId == null
        ? "'root' in parents and trashed = false"
        : "'$folderId' in parents and trashed = false";

    final fileList = await _driveApi!.files.list(
      q: query,
      orderBy: 'folder,name',
      spaces: 'drive',
      $fields: 'files(id,name,mimeType,size,modifiedTime)',
    );

    return (fileList.files ?? []).map((file) {
      final isDir =
          file.mimeType == 'application/vnd.google-apps.folder';
      return CloudFile(
        id: file.id!,
        name: file.name!,
        path: file.name!, // We'd need to build full path if needed
        isDirectory: isDir,
        size: file.size != null ? int.parse(file.size!) : null,
        modifiedTime: file.modifiedTime,
        mimeType: file.mimeType,
      );
    }).toList();
  }

  @override
  Future<List<int>> downloadFile(String fileId) async {
    if (_driveApi == null) throw Exception('Not authenticated');

    final response = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (var chunk in response.stream) {
      bytes.addAll(chunk);
    }

    return bytes;
  }

  @override
  Future<CloudFile> uploadFile({
    required String name,
    required List<int> content,
    String? parentFolderId,
    String? mimeType,
  }) async {
    if (_driveApi == null) throw Exception('Not authenticated');

    final file = drive.File();
    file.name = name;
    file.mimeType = mimeType;
    if (parentFolderId != null) {
      file.parents = [parentFolderId];
    }

    final media = drive.Media(
      Stream.value(content),
      content.length,
    );

    final uploadedFile = await _driveApi!.files.create(
      file,
      uploadMedia: media,
    );

    return CloudFile(
      id: uploadedFile.id!,
      name: uploadedFile.name!,
      path: uploadedFile.name!,
      isDirectory: false,
      size: content.length,
      mimeType: mimeType,
    );
  }

  @override
  Future<CloudFile> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    if (_driveApi == null) throw Exception('Not authenticated');

    final folder = drive.File();
    folder.name = name;
    folder.mimeType = 'application/vnd.google-apps.folder';
    if (parentFolderId != null) {
      folder.parents = [parentFolderId];
    }

    final createdFolder = await _driveApi!.files.create(folder);

    return CloudFile(
      id: createdFolder.id!,
      name: createdFolder.name!,
      path: createdFolder.name!,
      isDirectory: true,
      mimeType: 'application/vnd.google-apps.folder',
    );
  }

  @override
  Future<void> delete(String fileId) async {
    if (_driveApi == null) throw Exception('Not authenticated');
    await _driveApi!.files.delete(fileId);
  }

  @override
  Future<List<CloudFile>> search(String query) async {
    if (_driveApi == null) throw Exception('Not authenticated');

    final searchQuery = "name contains '$query' and trashed = false";
    final fileList = await _driveApi!.files.list(
      q: searchQuery,
      orderBy: 'folder,name',
      spaces: 'drive',
      $fields: 'files(id,name,mimeType,size,modifiedTime)',
    );

    return (fileList.files ?? []).map((file) {
      final isDir =
          file.mimeType == 'application/vnd.google-apps.folder';
      return CloudFile(
        id: file.id!,
        name: file.name!,
        path: file.name!,
        isDirectory: isDir,
        size: file.size != null ? int.parse(file.size!) : null,
        modifiedTime: file.modifiedTime,
        mimeType: file.mimeType,
      );
    }).toList();
  }

  @override
  Future<CloudFile> getFile(String fileId) async {
    if (_driveApi == null) throw Exception('Not authenticated');

    final file = await _driveApi!.files.get(
      fileId,
      $fields: 'id,name,mimeType,size,modifiedTime',
    ) as drive.File;

    final isDir = file.mimeType == 'application/vnd.google-apps.folder';
    return CloudFile(
      id: file.id!,
      name: file.name!,
      path: file.name!,
      isDirectory: isDir,
      size: file.size != null ? int.parse(file.size!) : null,
      modifiedTime: file.modifiedTime,
      mimeType: file.mimeType,
    );
  }
}

/// HTTP client with authentication headers
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
