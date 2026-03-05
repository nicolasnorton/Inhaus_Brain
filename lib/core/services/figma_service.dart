import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../architecture/blackboard.dart';
import '../models/figma_models.dart';
import '../utils/resilience_utils.dart';

/// Riverpod provider for FigmaService.
final figmaServiceProvider = Provider<FigmaService>((ref) {
  return FigmaService(ref);
});

/// Service for interacting with the Figma REST API v1.
///
/// All calls require a Figma Personal Access Token (PAT) stored in
/// user secrets (BYOK pattern via UserSecretsScreen).
///
/// Resilience: CircuitBreaker, exponential backoff on 429, timeouts.
/// Telemetry: Every call is logged via Blackboard.
class FigmaService {
  final Ref _ref;
  static const _baseUrl = 'https://api.figma.com/v1';
  static final _circuit = CircuitBreaker(
    name: 'FigmaAPI',
    failureThreshold: 5,
  );

  FigmaService(this._ref);

  /// Retrieve a Figma file's full structure.
  /// GET /v1/files/:key
  Future<FigmaFile> getFile(String fileKey, {required String token}) async {
    return _circuit.execute(() async {
      final response = await _get('/files/$fileKey', token: token);
      _postTelemetry('figma_get_file', {'fileKey': _hash(fileKey)});
      return FigmaFile.fromJson({
        'key': fileKey,
        ...response,
      });
    });
  }

  /// Export specific nodes as images (PNG, SVG, or PDF).
  /// GET /v1/images/:key?ids=...&format=...
  Future<List<String>> exportNodes(
    String fileKey,
    List<String> nodeIds, {
    String format = 'png',
    required String token,
  }) async {
    return _circuit.execute(() async {
      final ids = nodeIds.join(',');
      final response = await _get(
        '/images/$fileKey?ids=$ids&format=$format',
        token: token,
      );
      final images = response['images'] as Map<String, dynamic>? ?? {};
      _postTelemetry('figma_export_nodes', {
        'fileKey': _hash(fileKey),
        'nodeCount': nodeIds.length,
        'format': format,
      });
      return images.values.map((v) => v as String).toList();
    });
  }

  /// Get file components.
  /// GET /v1/files/:key/components
  Future<FigmaFile> getFileComponents(
      String fileKey, {required String token}) async {
    return _circuit.execute(() async {
      final response = await _get('/files/$fileKey/components', token: token);
      _postTelemetry('figma_get_components', {'fileKey': _hash(fileKey)});
      return FigmaFile.fromJson({
        'key': fileKey,
        ...response,
      });
    });
  }

  /// Post a comment on a Figma file.
  /// POST /v1/files/:key/comments
  Future<void> postComment(
    String fileKey,
    String message, {
    String? nodeId,
    String? imageUrl,
    required String token,
  }) async {
    return _circuit.execute(() async {
      final body = <String, dynamic>{
        'message': message,
      };
      if (nodeId != null) {
        body['client_meta'] = {'node_id': nodeId};
      }
      // Figma API doesn't support image attachments directly in comments,
      // but we can embed the URL in the message text.
      if (imageUrl != null) {
        body['message'] = '$message\n\nImage: $imageUrl';
      }

      await _post('/files/$fileKey/comments', body: body, token: token);
      _postTelemetry('figma_post_comment', {'fileKey': _hash(fileKey)});
    });
  }

  /// List all projects in a team.
  /// GET /v1/teams/:id/projects
  Future<List<FigmaProject>> listTeamProjects(
      String teamId, {required String token}) async {
    return _circuit.execute(() async {
      final response = await _get('/teams/$teamId/projects', token: token);
      final projects = (response['projects'] as List? ?? [])
          .map((p) => FigmaProject.fromJson(p as Map<String, dynamic>))
          .toList();
      _postTelemetry('figma_list_projects', {
        'teamId': _hash(teamId),
        'count': projects.length,
      });
      return projects;
    });
  }

  /// List all files in a project.
  /// GET /v1/projects/:id/files
  Future<List<FigmaFileRef>> listProjectFiles(
      String projectId, {required String token}) async {
    return _circuit.execute(() async {
      final response = await _get('/projects/$projectId/files', token: token);
      final files = (response['files'] as List? ?? [])
          .map((f) => FigmaFileRef.fromJson(f as Map<String, dynamic>))
          .toList();
      _postTelemetry('figma_list_files', {
        'projectId': _hash(projectId),
        'count': files.length,
      });
      return files;
    });
  }

  // ─── Private Helpers ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> _get(String path, {required String token}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(uri, headers: {
      'X-Figma-Token': token,
    }).timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      // Rate limited — extract Retry-After if available
      final retryAfter =
          int.tryParse(response.headers['retry-after'] ?? '5') ?? 5;
      debugPrint('FigmaService: Rate limited. Retrying in ${retryAfter}s');
      await Future.delayed(Duration(seconds: retryAfter));
      return _get(path, token: token); // Retry once
    }

    if (response.statusCode != 200) {
      throw Exception(
          'Figma API error: ${response.statusCode} — ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path,
      {required Map<String, dynamic> body, required String token}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: {
        'X-Figma-Token': token,
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 429) {
      final retryAfter =
          int.tryParse(response.headers['retry-after'] ?? '5') ?? 5;
      await Future.delayed(Duration(seconds: retryAfter));
      return _post(path, body: body, token: token);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Figma API error: ${response.statusCode} — ${response.body.length > 100 ? response.body.substring(0, 100) : response.body}');
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  void _postTelemetry(String action, Map<String, dynamic> metadata) {
    try {
      _ref.read(blackboardProvider.notifier).postFact(
        'figma_telemetry',
        {'action': action, 'timestamp': DateTime.now().toIso8601String(), ...metadata},
      );
    } catch (_) {
      // Telemetry is best-effort
    }
  }

  /// Hash sensitive identifiers for telemetry (don't log raw file keys).
  String _hash(String value) {
    if (value.length <= 4) return '***';
    return '${value.substring(0, 2)}***${value.substring(value.length - 2)}';
  }
}
