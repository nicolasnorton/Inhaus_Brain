import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../auth/auth_service.dart';

class GoogleDriveFile {
  final String id;
  final String name;
  final String mimeType;
  final String? webViewLink;

  GoogleDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.webViewLink,
  });

  factory GoogleDriveFile.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFile(
      id: json['id'],
      name: json['name'],
      mimeType: json['mimeType'],
      webViewLink: json['webViewLink'],
    );
  }
}

class GoogleDriveService {
  final AuthService _auth;

  GoogleDriveService(this._auth);

  Future<List<GoogleDriveFile>> listRecentFiles({int pageSize = 20}) async {
    final token = await _auth.getFreshVertexToken(); // This refreshes the token with the right scopes if setup correctly
    if (token == null) throw Exception('Google Drive access required. Please sign in with Google.');

    final url = Uri.parse('https://www.googleapis.com/drive/v3/files?pageSize=$pageSize&fields=files(id,name,mimeType,webViewLink)&q=trashed=false');
    
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final files = (data['files'] as List).map((f) => GoogleDriveFile.fromJson(f)).toList();
      return files;
    } else {
      throw Exception('Failed to list Drive files: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Uint8List> downloadFile(String fileId) async {
    final token = await _auth.getFreshVertexToken();
    if (token == null) throw Exception('Google Drive access required.');

    // For Google Docs (gdoc, gsheet, etc.), we must export them
    // For binary files, we can download directly
    
    // First, get metadata to check mimeType
    final metaUrl = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?fields=mimeType,name');
    final metaRes = await http.get(metaUrl, headers: {'Authorization': 'Bearer $token'});
    if (metaRes.statusCode != 200) throw Exception('Failed to get file metadata');
    final meta = jsonDecode(metaRes.body);
    final mimeType = meta['mimeType'] as String;

    Uri downloadUrl;
    if (mimeType.startsWith('application/vnd.google-apps.')) {
      // Export mapping
      String exportMime;
      if (mimeType.contains('document')) {
        exportMime = 'application/pdf'; // Export docs as PDF
      } else if (mimeType.contains('spreadsheet')) {
        exportMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (mimeType.contains('presentation')) {
        exportMime = 'application/pdf';
      } else {
        exportMime = 'application/pdf';
      }
      downloadUrl = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId/export?mimeType=$exportMime');
    } else {
      downloadUrl = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId?alt=media');
    }

    final response = await http.get(
      downloadUrl,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download Drive file: ${response.statusCode} - ${response.body}');
    }
  }
}
