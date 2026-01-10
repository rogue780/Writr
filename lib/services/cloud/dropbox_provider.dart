import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cloud_storage.dart';
import '../cloud_storage_service.dart';

class DropboxProvider implements CloudProviderInterface {
  static const String _appKey = 'YOUR_DROPBOX_APP_KEY';
  static const String _redirectUri = 'writr://auth';
  static const String _tokenKey = 'dropbox_access_token';

  String? _accessToken;
  bool _isAuthenticated = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  DropboxProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _isAuthenticated = _accessToken != null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _accessToken = token;
    _isAuthenticated = true;
  }

  @override
  Future<void> authenticate() async {
    // OAuth 2.0 flow for Dropbox
    final authUrl = Uri.parse(
      'https://www.dropbox.com/oauth2/authorize?'
      'client_id=$_appKey&'
      'response_type=token&'
      'redirect_uri=$_redirectUri',
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      // Note: In a real implementation, you would need to handle the callback
      // and extract the access token from the redirect URI
      // For now, this is a placeholder implementation
      throw UnimplementedError(
        'Dropbox authentication requires callback handling. '
        'Please configure your Dropbox app settings.',
      );
    } else {
      throw Exception('Could not launch Dropbox authentication');
    }
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _accessToken = null;
    _isAuthenticated = false;
  }

  @override
  Future<List<CloudFile>> listFiles(String? parentId) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated with Dropbox');
    }

    final path = parentId ?? '';
    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/list_folder'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'path': path,
        'recursive': false,
        'include_deleted': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list files: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final entries = data['entries'] as List;

    return entries.map((entry) {
      return CloudFile(
        id: entry['id'] as String,
        name: entry['name'] as String,
        path: entry['path_display'] as String,
        provider: CloudProvider.dropbox,
        isDirectory: entry['.tag'] == 'folder',
        modifiedTime: entry['server_modified'] != null
            ? DateTime.parse(entry['server_modified'])
            : null,
        size: entry['size'] as int?,
      );
    }).toList();
  }

  @override
  Future<String> downloadFile(String fileId, String localPath) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated with Dropbox');
    }

    final response = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Dropbox-API-Arg': jsonEncode({'path': fileId}),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download file: ${response.body}');
    }

    final file = File(localPath);
    await file.writeAsBytes(response.bodyBytes);

    return localPath;
  }

  @override
  Future<void> uploadFile(String localPath, String? parentId) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated with Dropbox');
    }

    final file = File(localPath);
    final fileName = file.path.split('/').last;
    final dropboxPath = parentId != null ? '$parentId/$fileName' : '/$fileName';

    final response = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/upload'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': jsonEncode({
          'path': dropboxPath,
          'mode': 'add',
          'autorename': true,
        }),
      },
      body: await file.readAsBytes(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }

  @override
  Future<void> deleteFile(String fileId) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated with Dropbox');
    }

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'path': fileId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.body}');
    }
  }
}
