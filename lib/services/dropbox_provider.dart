import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cloud_file.dart';
import 'cloud_storage_provider.dart';

class DropboxProvider implements CloudStorageProvider {
  static const String _appKey =
      'YOUR_DROPBOX_APP_KEY'; // Replace with your app key
  static const String _redirectUri = 'writr://oauth2redirect';
  static const String _tokenKey = 'dropbox_access_token';

  String? _accessToken;

  @override
  String get providerName => 'Dropbox';

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
        await _getCurrentAccount();
        return true;
      } catch (e) {
        // Token invalid, clear it
        _accessToken = null;
        await prefs.remove(_tokenKey);
      }
    }

    // Start OAuth flow
    final authUrl = Uri.https('www.dropbox.com', '/oauth2/authorize', {
      'client_id': _appKey,
      'response_type': 'token',
      'redirect_uri': _redirectUri,
    });

    if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch Dropbox auth');
    }

    // Note: In a real implementation, you'd need to handle the OAuth redirect
    // and extract the access token. This is simplified for demonstration.
    // You might want to use flutter_web_auth or similar package.

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

  Future<Map<String, dynamic>> _getCurrentAccount() async {
    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/users/get_current_account'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get account info: ${response.body}');
    }

    return json.decode(response.body);
  }

  @override
  Future<List<CloudFile>> listFiles({String? folderId}) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/list_folder'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'path': folderId ?? '',
        'recursive': false,
        'include_deleted': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list files: ${response.body}');
    }

    final data = json.decode(response.body);
    final entries = data['entries'] as List;

    return entries.map((entry) {
      final isDir = entry['.tag'] == 'folder';
      return CloudFile(
        id: entry['path_lower'],
        name: entry['name'],
        path: entry['path_display'],
        isDirectory: isDir,
        size: isDir ? null : entry['size'],
        modifiedTime:
            isDir ? null : DateTime.parse(entry['client_modified']),
      );
    }).toList();
  }

  @override
  Future<List<int>> downloadFile(String fileId) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Dropbox-API-Arg': json.encode({'path': fileId}),
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

    final path = parentFolderId != null ? '$parentFolderId/$name' : '/$name';

    final response = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/upload'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/octet-stream',
        'Dropbox-API-Arg': json.encode({
          'path': path,
          'mode': 'overwrite',
          'autorename': false,
        }),
      },
      body: content,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload file: ${response.body}');
    }

    final data = json.decode(response.body);
    return CloudFile(
      id: data['path_lower'],
      name: data['name'],
      path: data['path_display'],
      isDirectory: false,
      size: data['size'],
      modifiedTime: DateTime.parse(data['client_modified']),
    );
  }

  @override
  Future<CloudFile> createFolder({
    required String name,
    String? parentFolderId,
  }) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final path = parentFolderId != null ? '$parentFolderId/$name' : '/$name';

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/create_folder_v2'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'path': path,
        'autorename': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create folder: ${response.body}');
    }

    final data = json.decode(response.body)['metadata'];
    return CloudFile(
      id: data['path_lower'],
      name: data['name'],
      path: data['path_display'],
      isDirectory: true,
    );
  }

  @override
  Future<void> delete(String fileId) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'path': fileId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete: ${response.body}');
    }
  }

  @override
  Future<List<CloudFile>> search(String query) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/search_v2'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'query': query,
        'options': {
          'path': '',
          'max_results': 100,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search: ${response.body}');
    }

    final data = json.decode(response.body);
    final matches = data['matches'] as List;

    return matches.map((match) {
      final metadata = match['metadata']['metadata'];
      final isDir = metadata['.tag'] == 'folder';
      return CloudFile(
        id: metadata['path_lower'],
        name: metadata['name'],
        path: metadata['path_display'],
        isDirectory: isDir,
        size: isDir ? null : metadata['size'],
        modifiedTime:
            isDir ? null : DateTime.parse(metadata['client_modified']),
      );
    }).toList();
  }

  @override
  Future<CloudFile> getFile(String fileId) async {
    if (_accessToken == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/get_metadata'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'path': fileId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get file metadata: ${response.body}');
    }

    final data = json.decode(response.body);
    final isDir = data['.tag'] == 'folder';
    return CloudFile(
      id: data['path_lower'],
      name: data['name'],
      path: data['path_display'],
      isDirectory: isDir,
      size: isDir ? null : data['size'],
      modifiedTime:
          isDir ? null : DateTime.parse(data['client_modified']),
    );
  }
}
