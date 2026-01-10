import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../../models/cloud_storage.dart';
import '../cloud_storage_service.dart';

class GoogleDriveProvider implements CloudProviderInterface {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  drive.DriveApi? _driveApi;
  bool _isAuthenticated = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<void> authenticate() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google sign-in cancelled');
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(authenticateClient);
      _isAuthenticated = true;
    } catch (e) {
      _isAuthenticated = false;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _isAuthenticated = false;
  }

  @override
  Future<List<CloudFile>> listFiles(String? parentId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated with Google Drive');
    }

    final query = parentId != null
        ? "'$parentId' in parents and trashed=false"
        : "'root' in parents and trashed=false";

    final fileList = await _driveApi!.files.list(
      q: query,
      spaces: 'drive',
      $fields: 'files(id, name, mimeType, modifiedTime, size)',
    );

    return (fileList.files ?? []).map((file) {
      return CloudFile(
        id: file.id!,
        name: file.name ?? 'Untitled',
        path: file.name ?? '',
        provider: CloudProvider.googleDrive,
        isDirectory: file.mimeType == 'application/vnd.google-apps.folder',
        modifiedTime: file.modifiedTime,
        size: file.size != null ? int.tryParse(file.size!) : null,
      );
    }).toList();
  }

  @override
  Future<String> downloadFile(String fileId, String localPath) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated with Google Drive');
    }

    final file = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final localFile = File(localPath);
    final sink = localFile.openWrite();

    await for (final data in file.stream) {
      sink.add(data);
    }
    await sink.close();

    return localPath;
  }

  @override
  Future<void> uploadFile(String localPath, String? parentId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated with Google Drive');
    }

    final file = File(localPath);
    final fileName = file.path.split('/').last;

    final driveFile = drive.File();
    driveFile.name = fileName;
    if (parentId != null) {
      driveFile.parents = [parentId];
    }

    final media = drive.Media(file.openRead(), file.lengthSync());

    await _driveApi!.files.create(
      driveFile,
      uploadMedia: media,
    );
  }

  @override
  Future<void> deleteFile(String fileId) async {
    if (_driveApi == null) {
      throw Exception('Not authenticated with Google Drive');
    }

    await _driveApi!.files.delete(fileId);
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
