import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../config/feature_flags.dart';
import '../architecture/blackboard.dart';
import 'semantic_cache_service.dart';
import 'telemetry_service.dart';
import '../models/stitch_models.dart';

class StitchService {
  final Ref _ref;
  
  // Service Dependencies
  late final BlackboardNotifier _blackboard;
  late final SemanticCacheService _cache;
  late final TelemetryService _telemetry;

  StitchService(this._ref) {
    _blackboard = _ref.read(blackboardProvider.notifier);
    _cache = _ref.read(semanticCacheServiceProvider);
    _telemetry = _ref.read(telemetryServiceProvider);
  }

  static String get _proxyUrl {
    // Both environments point to the same Cloud Function host for now, 
    // but we can differentiate if needed.
    return 'https://us-central1-inhausbrain.cloudfunctions.net/proxyStitch';
  }

  /// Helper: Check feature flag
  void _checkFeature() {
    if (!FeatureFlags.enableStitch) {
      throw Exception('Stitch integration is currently disabled via feature flags.');
    }
  }

  /// Helper: Authenticated Proxy Call
  Future<dynamic> _callProxy(String action, Map<String, dynamic> payload) async {
    _checkFeature();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be logged in to use Stitch.');
    final idToken = await user.getIdToken();

    final startTime = DateTime.now();
    bool success = false;
    String? error;

    try {
      final response = await http.post(
        Uri.parse(_proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'action': action,
          'payload': payload,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        success = true;
        return jsonDecode(response.body);
      } else {
        // Try to parse error message from body
        String errorMessage = 'Stitch Proxy Error ${response.statusCode}';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody['error'] != null) {
            errorMessage = errBody['error'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      // Log telemetry
      try {
        _telemetry.logEvent(
          name: 'stitch_api_call',
          parameters: {
            'action': action,
            'duration_ms': DateTime.now().difference(startTime).inMilliseconds,
            'success': success,
            'error': error ?? '',
          },
        );
      } catch (_) {
        // Suppress telemetry errors
      }
    }
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Create a new Stitch Project
  Future<StitchProject> createProject({
    required String name,
    String? description,
  }) async {
    final result = await _callProxy('create_project', {
      'name': name,
      'description': description,
    });
    
    final project = StitchProject.fromJson(result);
    
    // Post fact to Blackboard
    _blackboard.postFact('stitch_active_project', project.id);
    
    return project;
  }

  /// List available Stitch Projects
  Future<List<StitchProject>> listProjects({int pageSize = 10, String? pageToken}) async {
    final result = await _callProxy('list_projects', {
      'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
    });

    final List items = result['projects'] ?? [];
    return items.map((json) => StitchProject.fromJson(json)).toList();
  }

  /// Generate a screen based on a prompt
  Future<StitchScreen> generateScreen({
    required String projectId,
    required String prompt,
    String? screenId, // If refining an existing screen
  }) async {
    // Semantic Cache Check
    final cacheKey = 'stitch_gen_${projectId}_$prompt';
    final cached = await _cache.lookup(cacheKey);
    if (cached != null) {
      debugPrint('StitchService: Cache hit for screen generation.');
      // We stored the JSON result in cache
      // The cached value should be the full StitchScreen JSON
      final screen = StitchScreen.fromJson(cached);
      _blackboard.postFact('stitch_last_screen', screen.id);
      return screen;
    }

    final result = await _callProxy('generate_screen', {
      'projectId': projectId,
      'prompt': prompt,
      if (screenId != null) 'screenId': screenId,
    });

    final screen = StitchScreen.fromJson(result);
    
    // Cache result
    await _cache.store(cacheKey, result);
    
    // Update Blackboard
    _blackboard.postFact('stitch_last_screen', screen.id);
    
    return screen;
  }

  /// Get the generated code for a screen
  Future<String> getScreenCode({
    required String projectId,
    required String screenId,
  }) async {
    final result = await _callProxy('get_screen_code', {
      'projectId': projectId,
      'screenId': screenId,
    });

    return result['code_content'] ?? '';
  }

  /// Get the screenshot/image of a screen
  Future<String> getScreenImage({
    required String projectId,
    required String screenId,
  }) async {
    final result = await _callProxy('get_screen_image', {
      'projectId': projectId,
      'screenId': screenId,
    });

    return result['image_url'] ?? '';
  }

  /// Extract design context (styles/components) from a screen
  Future<DesignContext> extractDesignContext({
    required String projectId,
    required String screenId,
  }) async {
    final result = await _callProxy('extract_design_context', {
      'projectId': projectId,
      'screenId': screenId,
    });

    final context = DesignContext.fromJson(result);
    
    // Post to Blackboard for agents to use
    _blackboard.postFact('stitch_design_context', result);
    
    return context;
  }

  /// Build a deployed site
  Future<SiteBuild> buildSite({
    required String projectId,
    required List<String> routeScreenIds, // Map routes to screen IDs? Simplified for now.
  }) async {
    final result = await _callProxy('build_site', {
      'projectId': projectId,
      'routes': routeScreenIds,
    });

    return SiteBuild.fromJson(result);
  }
}

final stitchServiceProvider = Provider<StitchService>((ref) => StitchService(ref));
