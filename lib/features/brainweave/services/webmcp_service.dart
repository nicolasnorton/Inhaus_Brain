@JS()
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'brainweave_mcp_client.dart';

// ─── JS Interop Bindings for WebMCP (Chrome 146+) ──────────────────────────
import 'package:inhaus_brain/core/config/feature_flags.dart';

@JS('navigator.modelContext')
external JSAny? get modelContext;

@JS('navigator.modelContext.registerTool')
external void _registerToolJS(
  JSString name,
  JSObject description,
  JSExportedDartFunction handler,
);

// ─── WebMcp Service ─────────────────────────────────────────────────────────

/// A service to expose BrainWeave capabilities to browser-based agents via WebMCP.
class WebMcpService {
  static final WebMcpService _instance = WebMcpService._internal();
  factory WebMcpService() => _instance;
  WebMcpService._internal();

  BrainWeaveMcpClient? _mcpClient;
  bool _isRegistered = false;

  static const String _consentKey = 'webmcp_consent_granted';

  Future<void> initialize(BrainWeaveMcpClient client) async {
    if (!kIsWeb) return; // Only relevant for Flutter Web
    if (_isRegistered) return;

    _mcpClient = client;

    // Check if browser supports modelContext (Chrome 146+)
    if (modelContext.isUndefinedOrNull) {
      debugPrint('WebMCP: navigator.modelContext not available in this browser.');
      return;
    }

    debugPrint('WebMCP: Registering Inhaus Brain tools to navigator.modelContext.');

    _registerGraphQuery();
    _registerImpact();
    _registerContext();
    _registerMeetingSync();
    _registerWiki();

    _isRegistered = true;
  }

  // ─── Consent Management ────────────────────────────────────────────────────

  Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  Future<void> setConsent(bool isGranted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, isGranted);
  }

  Future<void> _checkConsentOrThrow() async {
    if (!await hasConsent()) {
      throw Exception('USER_CONSENT_REQUIRED: User has not allowed agent actions on this tab.');
    }
  }

  // ─── Chrome Extension Execution ────────────────────────────────────────────

  /// Executes a tool in the local Chrome extension sandbox
  Future<Map<String, dynamic>> executeExtensionTool(String toolName, Map<String, dynamic> args) async {
    if (!FeatureFlags.inhausChromeCliEnabled) {
      throw Exception('Chrome CLI extensions are disabled via feature flag');
    }
    await _checkConsentOrThrow();
    
    // In a full implementation, we would use window.postMessage here to 
    // invoke the background.js extension worker. 
    // Example: window.postMessage({'action': 'execute_tool', 'toolName': toolName}, '*');
    debugPrint('WebMCP [Extension]: Executing $toolName locally');
    return {'status': 'success', 'mock_result': 'Extension interaction registered'};
  }

  // ─── Context Helpers ───────────────────────────────────────────────────────

  /// Gets ephemeral state like the query params or fragment context
  Map<String, dynamic> _getLocalContext() {
    return {
      'url': Uri.base.toString(),
      'time': DateTime.now().toIso8601String(),
    };
  }

  // ─── Tool Registrations (JS Interop + Dart Handlers) ──────────────────────

  void _registerGraphQuery() {
    final dartHandler = (JSString queryStr, JSObject? args) {
      return futureToPromise(() async {
        await _checkConsentOrThrow();
        final res = await _mcpClient!.graphQuery(
          query: queryStr.toDart,
          activeContext: _getLocalContext(),
        );
        return {
          'status': 'success',
          'source': 'webmcp',
          'context': _getLocalContext(),
          'results': res,
        }.jsify();
      }());
    }.toJS;

    final desc = {
      'description': 'Semantic vector search across the Inhaus BrainWeave knowledge graph.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'}
        },
        'required': ['query']
      }
    }.jsify();

    _registerToolJS('brainweave_graph_query'.toJS, desc as JSObject, dartHandler);
  }

  void _registerImpact() {
    final dartHandler = (JSString nodeId, JSObject? args) {
      return futureToPromise(() async {
        await _checkConsentOrThrow();
        final res = await _mcpClient!.impact(
          nodeId: nodeId.toDart,
          activeContext: _getLocalContext(),
        );
        return {
          'status': 'success',
          'source': 'webmcp',
          'context': _getLocalContext(),
          'impact': res,
        }.jsify();
      }());
    }.toJS;

    final desc = {
      'description': 'Find all nodes affected by changes to a given node.',
      'parameters': {
        'type': 'object',
        'properties': {
          'nodeId': {'type': 'string'}
        },
        'required': ['nodeId']
      }
    }.jsify();

    _registerToolJS('brainweave_impact'.toJS, desc as JSObject, dartHandler);
  }

  void _registerContext() {
    final dartHandler = (JSString nodeId, JSObject? args) {
      return futureToPromise(() async {
        await _checkConsentOrThrow();
        final res = await _mcpClient!.context(
          nodeId: nodeId.toDart,
          activeContext: _getLocalContext(),
        );
        return {
          'status': 'success',
          'source': 'webmcp',
          'context': _getLocalContext(),
          'data': res,
        }.jsify();
      }());
    }.toJS;

    final desc = {
      'description': 'Get full incoming and outgoing context for a specific node.',
      'parameters': {
        'type': 'object',
        'properties': {
          'nodeId': {'type': 'string'}
        },
        'required': ['nodeId']
      }
    }.jsify();

    _registerToolJS('brainweave_context'.toJS, desc as JSObject, dartHandler);
  }

  void _registerMeetingSync() {
    final dartHandler = (JSString transcript, JSObject? args) {
      return futureToPromise(() async {
        await _checkConsentOrThrow();
        final res = await _mcpClient!.meetingSync(transcript: transcript.toDart);
        // Note: meetingSync doesn't currently accept activeContext in brainweave_mcp_client.dart
        // (Will skip appending for brevity or we can add it later).
        return res.jsify();
      }());
    }.toJS;

    final desc = {
      'description': 'Extract structured knowledge from a meeting transcript.',
      'parameters': {
        'type': 'object',
        'properties': {
          'transcript': {'type': 'string'}
        },
        'required': ['transcript']
      }
    }.jsify();

    _registerToolJS('brainweave_meeting_sync'.toJS, desc as JSObject, dartHandler);
  }

  void _registerWiki() {
    final dartHandler = (JSString nodeId, JSObject? args) {
      return futureToPromise(() async {
        await _checkConsentOrThrow();
        final res = await _mcpClient!.wikiGenerate(
          nodeId: nodeId.toDart,
          activeContext: _getLocalContext(),
        );
        return res.jsify();
      }());
    }.toJS;

    final desc = {
      'description': 'Generates an LLM-structured Markdown document representing a subgraph around the active tab constraints.',
      'parameters': {
        'type': 'object',
        'properties': {
          'nodeId': {'type': 'string'}
        },
        'required': ['nodeId']
      }
    }.jsify();

    _registerToolJS('brainweave_wiki'.toJS, desc as JSObject, dartHandler);
  }
}

// Helper to convert Dart Future to JS Promise
// Using package:js_interop, we need to return JSPromise
@JS('Promise')
extension type JSPromise._(JSObject _) implements JSObject {
  external factory JSPromise(JSExportedDartFunction executor);
}

JSPromise futureToPromise<T>(Future<T> future) {
  return JSPromise((JSFunction resolve, JSFunction reject) {
    future.then((result) {
      resolve.callAsFunction(null, (result as dynamic)?.jsify());
    }).catchError((error) {
       reject.callAsFunction(null, error.toString().toJS);
    });
  }.toJS);
}
