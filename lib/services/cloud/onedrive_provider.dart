import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cloud_storage.dart';
import '../cloud_storage_service.dart';

class OneDriveProvider implements CloudProviderInterface {
  static const String _clientId = 'YOUR_MICROSOFT_CLIENT_ID';
  static const String _redirectUri = 'writr://auth';
  static const String _tokenKey = 'onedrive_access_token';
  static const String _refreshTokenKey = 'onedrive_refresh_token';

  String? _accessToken;
  String? _refreshToken;
  bool _isAuthenticated = false;

  @override
  bool get isAuthenticated => _isAuthenticated;

  OneDriveProvider() {
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _isAuthenticated = _accessToken != null;
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _isAuthenticated = true;
  }

  @override
  Future<void> authenticate() async {
    // Microsoft OAuth 2.0 flow
    final authUrl = Uri.parse(
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize?'
      'client_id=$_clientId&'
      'response_type=code&'
      'redirect_uri=$_redirectUri&'
      'scope=Files.ReadWrite.All offline_access',
    );

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      // Note: In a real implementation, you would need to handle the callback
      // and exchange the authorization code for an access token
      // For now, this is a placeholder implementation
      throw UnimplementedError(
        'OneDrive authentication requires callback handling. '
        'Please configure your Microsoft Azure app settings.',
      );
    } else {
      throw Exception('Could not launch OneDrive authentication');
    }
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
  }

  @override
  Future<List<CloudFile>> listFiles(String? parentId) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated with OneDrive');
    }

    final path = parentId != null
        ? 'https://graph.microsoft.com/v1.0/me/drive/items/$parentId/children'
        : 'https://graph.microsoft.com/v1.0/me/drive/root/children';

    final response = await http.get(
      Uri.parse(path),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list files: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final items = data['value'] as List;

    return items.map((item) {
      return CloudFile(
        id: item['id'] as String,
        name: item['name'] as String,
        path: item['name'] as String,
        provider: CloudProvider.oneDrive,
        isDirectory: item['folder'] != null,
        modifiedTime: item['lastModifiedDateTime'] != null
            ? DateTime.parse(item['lastModifiedDateTime'])
            : null,
        size: item['size'] as int?,
      );
    }).toList();
  }

  @override
  Future<String> downloadFile(String fileId, String localPath) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated with OneDrive');
    }

    final response = await http.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$fileId/content'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
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
      throw Exception('Not authenticated with OneDrive');
    }

    final file = File(localPath);
    final fileName = file.path.split('/').last;

    final uploadUrl = parentId != null
        ? 'https://graph.microsoft.com/v1.0/me/drive/items/$parentId:/$fileName:/content'
        : 'https://graph.microsoft.com/v1.0/me/drive/root:/$fileName:/content';

    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/octet-stream',
      },
      body: await file.readAsBytes(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }

  @override
  Future<void> deleteFile(String fileId) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated with OneDrive');
    }

    final response = await http.delete(
      Uri.parse('https://graph.microsoft.com/v1.0/me/drive/items/$fileId'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete file: ${response.body}');
    }
  }
}
