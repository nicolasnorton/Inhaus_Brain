import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../secret_vault_service.dart';

final contentCachingServiceProvider = Provider<ContentCachingService>((ref) {
  return ContentCachingService(ref);
});

class CachedContentResult {
  final String name;
  final String? expireTime;

  CachedContentResult({required this.name, this.expireTime});

  factory CachedContentResult.fromJson(Map<String, dynamic> json) {
    return CachedContentResult(
      name: json['name'] as String,
      expireTime: json['expireTime'] as String?,
    );
  }
}

class ContentCachingService {
  final Ref _ref;

  ContentCachingService(this._ref);

  static String get _projectSuffix => '-btdf7nijqa-uc.a.run.app';
  static String get _createCacheUrl => 'https://create-cache$_projectSuffix';

  Future<CachedContentResult> createCache({
    required String modelId,
    required List<Map<String, dynamic>> contents,
    int ttlSeconds = 3600,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to cache content.');
    }

    final idToken = await user.getIdToken();
    try {
      final response = await http.post(
        Uri.parse(_createCacheUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'model': modelId,
          'contents': contents,
          'ttl': ttlSeconds,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return CachedContentResult.fromJson(data);
      } else {
        throw Exception('Failed to create cache: ${response.body}');
      }
    } catch (e) {
      debugPrint('ContentCachingService Error: $e');
      rethrow;
    }
  }
}
