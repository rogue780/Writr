import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cloud_file.dart';
import 'cloud_storage_provider.dart';

class OneDriveProvider implements CloudStorageProvider {
  static const String _clientId =
      String.fromEnvironment('ONEDRIVE_CLIENT_ID', defaultValue: '');
  static const String _redirectUri = 'writr://auth';
  static const String _tokenKey = 'onedrive_access_token';

  String? _accessToken;

  @override
  String get providerName => 'OneDrive';

  @override
  bool get isAuthenticated => _accessToken != null;

  @override
  Future<bool> signIn() async {
    // Load saved token
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);

    if (_accessToken != null) {
      // Verify token is still valid
      try {
        await _getCurrentUser();
        return true;
      } catch (e) {
        // Token invalid, clear it
        _accessToken = null;
        await prefs.remove(_tokenKey);
      }
    }

    if (_clientId.isEmpty) {
      throw Exception(
        'OneDrive client ID not configured. '
        'Build/run with --dart-define=ONEDRIVE_CLIENT_ID=...',
      );
    }

    // Start OAuth flow
    final authUrl = Uri.https('login.microsoftonline.com', '/common/oauth2/v2.0/authorize', {
      'client_id': _clientId,
      'response_type': 'token',
      'redirect_uri': _redirectUri,
      'scope': 'files.readwrite offline_access',
    });

    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch OneDrive auth');
    }

    // Note: In a real implementation, you'd need to handle the OAuth redirect
    // and extract the access token. This is simplified for demonstration.

    return false; // Return true when token is obtained
  }

  /// Set access token manually (for testing or after OAuth flow)
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  @override
  Future<void> signOut() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> _getCurrentUser() async {
    final response = await http.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get user info: ${response.body}');
    }

    return json.decode(response.body);
  }

  @override
  Future<List<CloudFile>> listFiles({String? folderId}) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final endpoint = folderId == null
        ? 'https://graph.microsoft.com/v1.0/me/drive/root/children'
        : 'https://graph.microsoft.com/v1.0/me/drive/items/$folderId/children';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list files: ${response.body}');
    }

    final data = json.decode(response.body);
    final items = data['value'] as List;

    return items.map((item) {
      final isDir = item['folder'] != null;
      return CloudFile(
        id: item['id'],
        name: item['name'],
        path: item['name'], // Could use webUrl or parentReference for full path
        isDirectory: isDir,
        size: isDir ? null : item['size'],
        modifiedTime: DateTime.parse(item['lastModifiedDateTime']),
      );
    }).toList();
  }

  @override
  Future<List<int>> downloadFile(String fileId) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(
          'https://graph.microsoft.com/v1.0/me/drive/items/$fileId/content'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download file: ${response.body}');
    }

    return response.bodyBytes;
  }

  @override
  Future<CloudFile> uploadFile({
    required String name,
    required List<int> content,
    String? parentFolderId,
    String? mimeType,
  }) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final endpoint = parentFolderId == null
        ? 'https://graph.microsoft.com/v1.0/me/drive/root:/$name:/content'
        : 'https://graph.microsoft.com/v1.0/me/drive/items/$parentFolderId:/$name:/content';

    final response = await http.put(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': mimeType ?? 'application/octet-stream',
      },
      body: content,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload file: ${response.body}');
    }

    final data = json.decode(response.body);
    return CloudFile(
      id: data['id'],
      name: data['name'],
      path: data['name'],
      isDirectory: false,
      size: data['size'],
      modifiedTime: DateTime.parse(data['lastModifiedDateTime']),
    );
  }

  @override
  Future<CloudFile> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final endpoint = parentFolderId == null
        ? 'https://graph.microsoft.com/v1.0/me/drive/root/children'
        : 'https://graph.microsoft.com/v1.0/me/drive/items/$parentFolderId/children';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'folder': {},
        '@microsoft.graph.conflictBehavior': 'fail',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create folder: ${response.body}');
    }

    final data = json.decode(response.body);
    return CloudFile(
      id: data['id'],
      name: data['name'],
      path: data['name'],
      isDirectory: true,
      modifiedTime: DateTime.parse(data['lastModifiedDateTime']),
    );
  }

  @override
  Future<void> delete(String fileId) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$fileId'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete: ${response.body}');
    }
  }

  @override
  Future<List<CloudFile>> search(String query) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(
          'https://graph.microsoft.com/v1.0/me/drive/root/search(q=\'$query\')'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.body}');
    }

    final data = json.decode(response.body);
    final items = data['value'] as List;

    return items.map((item) {
      final isDir = item['folder'] != null;
      return CloudFile(
        id: item['id'],
        name: item['name'],
        path: item['name'],
        isDirectory: isDir,
        size: isDir ? null : item['size'],
        modifiedTime: DateTime.parse(item['lastModifiedDateTime']),
      );
    }).toList();
  }

  @override
  Future<CloudFile> getFile(String fileId) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$fileId'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get file: ${response.body}');
    }

    final data = json.decode(response.body);
    final isDir = data['folder'] != null;
    return CloudFile(
      id: data['id'],
      name: data['name'],
      path: data['name'],
      isDirectory: isDir,
      size: isDir ? null : data['size'],
      modifiedTime: DateTime.parse(data['lastModifiedDateTime']),
    );
  }
}
