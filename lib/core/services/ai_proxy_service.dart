import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../tokens/llm_provider.dart';
import '../utils/resilience_utils.dart';
import 'audit_log_service.dart';

class AIProxyService {
  static Ref? globalRef;
  final Ref _ref;

  // Circuit Breakers for production resilience
  static final _contentCircuit = CircuitBreaker(name: 'GeminiContent', failureThreshold: 5);
  static final _imageCircuit = CircuitBreaker(name: 'ImagenImage', failureThreshold: 3);

  AIProxyService(this._ref) {
    _globalRef = _ref;
  }

  /// Safe audit log helper — skips logging if ref hasn't been initialized yet.
  static void _auditLog({required String action, String? resourceType, String? resourceId, Map<String, dynamic>? metadata}) {
    try {
      _globalRef?.read(auditLogServiceProvider).log(
        action: action,
        resourceType: resourceType,
        resourceId: resourceId,
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('AIProxyService: Audit log skipped ($action): $e');
    }
  }

  static String get _functionUrl {
    if (kIsWeb) return 'https://us-central1-inhausbrain.cloudfunctions.net/proxyVertexAI';
    return 'https://us-central1-inhausbrain.cloudfunctions.net/proxyVertexAI';
  }

  static String get _pythonBaseUrl => 'https://generate-content-btdf7nijqa-uc.a.run.app'; 

  static String get _generateImageUrl => 'https://generate-image-btdf7nijqa-uc.a.run.app';
  static String get _generateContentUrl => 'https://generate-content-btdf7nijqa-uc.a.run.app';
  static String get _countTokensUrl => 'https://count-tokens-btdf7nijqa-uc.a.run.app';
  static String get _liveTokenUrl => 'https://get-live-token-btdf7nijqa-uc.a.run.app';
  static String get _startResearchUrl => 'https://start-research-btdf7nijqa-uc.a.run.app';
  static String get _pollResearchUrl => 'https://poll-research-btdf7nijqa-uc.a.run.app';
  static String get _pollOperationUrl => 'https://poll-operation-btdf7nijqa-uc.a.run.app';
  static String get _extractStructuredUrl => 'https://extract-structured-btdf7nijqa-uc.a.run.app';

  /// Fetch a short-lived access token for the Multimodal Live API.
  static Future<Map<String, dynamic>> getLiveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User must be logged in.');

    final idToken = await user.getIdToken();
    final response = await http.post(
      Uri.parse(_liveTokenUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get Live API Token: ${response.body}');
    }
  }

  /// Routes a generation request through the secure Cloud Function proxy.
  static Future<Map<String, dynamic>> generateContent({
    required dynamic prompt, 
    required AIModelConfig config,
    List<Map<String, dynamic>>? contextData, 
    String? systemInstruction,
    Map<String, dynamic>? generationParams,
    List<Map<String, dynamic>>? tools,
    bool thinking = false,
    bool audio = false,
    String? previousInteractionId,
    bool usePython = true,
    Ref? ref,
  }) async {
    final effectiveRef = ref ?? globalRef;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to use AI Proxy.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to retrieve ID Token.');
    }

    final body = {
      "model": config.modelId,
      "prompt": prompt,
      "useGoogleSearch": config.useGoogleSearch,
      "config": {
        "temperature": config.temperature,
        "maxOutputTokens": config.maxTokens,
        if (config.responseMimeType != null) "responseMimeType": config.responseMimeType,
      },
      if (systemInstruction != null) "systemInstruction": systemInstruction, 
      if (generationParams != null) "generationParams": generationParams,
      if (tools != null) "tools": tools,
      "thinking": thinking,
      "audio": audio,
      if (previousInteractionId != null) "previousInteractionId": previousInteractionId,
      if (config.thinkingLevel != null) "thinkingLevel": config.thinkingLevel,
      if (config.thinkingSummaries != null) "thinkingSummaries": config.thinkingSummaries,
      if (config.responseJsonSchema != null) "responseJsonSchema": config.responseJsonSchema,
    };

    if (usePython) {
      try {
        debugPrint('AIProxyService: 🐍 Routing to Python Gemini SDK (Thinking: $thinking)...');
        final response = await _contentCircuit.execute(() => http.post(
          Uri.parse(_generateContentUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 120)));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['error'] != null) {
             throw Exception('Python API Error: ${data['error']}');
          }
          
          if (effectiveRef != null) {
            effectiveRef.read(auditLogServiceProvider).log(
              action: 'ai/generate_content',
              resourceType: 'model',
              resourceId: config.modelId,
              metadata: {
                'promptLength': prompt.toString().length,
                'thinking': thinking,
                'audio': audio,
              }
            );
          }

          return data;
        } else {
          debugPrint('AIProxyService: Python Proxy failed (${response.statusCode}): ${response.body}');
          if (thinking || tools != null || prompt is List) {
             throw Exception('Python Proxy failed (${response.statusCode}) and features are not available in legacy fallback.');
          }
        }
      } catch (e) {
        debugPrint('AIProxyService Python Error: $e');
        if (thinking || tools != null || prompt is List) rethrow;
      }
    }

    // Legacy JS Proxy Fallback
    try {
      debugPrint('AIProxyService: 📦 Routing to Legacy JS Proxy...');
      final response = await _contentCircuit.execute(() => http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      ));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Proxy Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('AIProxyService Legacy Error: $e');
      rethrow;
    }
  }

  /// Generates an image using Imagen 3 via the Python proxy.
  static Future<Map<String, dynamic>> generateImage({
    required String prompt,
    String model = 'imagen-3',
    Map<String, dynamic>? config,
    Ref? ref,
  }) async {
    final effectiveRef = ref ?? globalRef;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final response = await _imageCircuit.execute(() => http.post(
      Uri.parse(_generateImageUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        "prompt": prompt,
        "model": model,
        "config": config ?? {},
      }),
    ).timeout(const Duration(seconds: 60)));

    if (response.statusCode == 200) {
      if (effectiveRef != null) {
        effectiveRef.read(auditLogServiceProvider).log(
          action: 'ai/generate_image',
          resourceType: 'model',
          resourceId: model,
          metadata: {'prompt': prompt}
        );
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('Image Generation Failed (${response.statusCode}): ${response.body}');
    }
  }

/// Generates an image using Nano Banana (Native Generation).
static Future<Map<String, dynamic>> generateNanoBanana({
  required String prompt,
  String model = 'gemini-2.5-flash-image',
  List<String> responseModalities = const ['Text', 'Image'],
  String? aspectRatio,
  String? imageSize,
  List<Map<String, dynamic>>? referenceImages,
  Ref? ref,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Unauthenticated');
  final idToken = await user.getIdToken();

  final response = await _imageCircuit.execute(() => http.post(
    Uri.parse('https://us-central1-inhausbrain.cloudfunctions.net/generate_nano_banana'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({
      "prompt": prompt,
      "model": model,
      "responseModalities": responseModalities,
      "aspectRatio": aspectRatio,
      "imageSize": imageSize,
      "referenceImages": referenceImages,
    }),
  ).timeout(const Duration(seconds: 60)));

  if (response.statusCode == 200) {
    if (ref != null) {
      ref.read(auditLogServiceProvider).log(
        action: 'ai/generate_nano_banana',
        resourceType: 'model',
        resourceId: model,
        metadata: {'prompt': prompt}
      );
    }
    return jsonDecode(response.body);
  } else {
    throw Exception('Nano Banana Generation Failed (${response.statusCode}): ${response.body}');
  }
}

/// Uploads a file via the Gemini Files API.
static Future<Map<String, dynamic>> uploadFile({
  required Uint8List fileBytes,
  required String mimeType,
  String? displayName,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Unauthenticated');
  final idToken = await user.getIdToken();

  final response = await _contentCircuit.execute(() => http.post(
    Uri.parse('https://us-central1-inhausbrain.cloudfunctions.net/upload_file'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({
      "data": base64Encode(fileBytes),
      "mimeType": mimeType,
      "displayName": displayName,
    }),
  ).timeout(const Duration(seconds: 300))); // Allow longer timeout for uploads

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('File Upload Failed (${response.statusCode}): ${response.body}');
  }
}

/// Processes a document for understanding/extraction.
static Future<Map<String, dynamic>> processDocument({
  String? fileUri,
  Map<String, dynamic>? inlineData, // {data: b64, mimeType: str}
  String prompt = "Analyze this document.",
  String model = 'gemini-2.0-flash',
  Map<String, dynamic>? responseJsonSchema,
  Ref? ref,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Unauthenticated');
  final idToken = await user.getIdToken();

  final response = await _contentCircuit.execute(() => http.post(
    Uri.parse('https://us-central1-inhausbrain.cloudfunctions.net/process_document'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({
      "prompt": prompt,
      "model": model,
      "fileUri": fileUri,
      "inlineData": inlineData,
      "responseJsonSchema": responseJsonSchema,
    }),
  ).timeout(const Duration(seconds: 120)));

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Document Processing Failed (${response.statusCode}): ${response.body}');
  }
}
  /// Starts a Deep Research task.
  static Future<Map<String, dynamic>> startResearch({
    required String prompt,
    String model = 'deep-research-pro-preview-12-2025',
    Ref? ref,
  }) async {
    final effectiveRef = ref ?? globalRef;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(_startResearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        "prompt": prompt,
        "model": model,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      if (effectiveRef != null) {
        effectiveRef.read(auditLogServiceProvider).log(
          action: 'ai/research_start',
          metadata: {'prompt': prompt}
        );
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('Start Research Failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Polls for Deep Research results.
  static Future<Map<String, dynamic>> pollResearch(String interactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(_pollResearchUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        "interactionId": interactionId,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Poll Research Failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Counts tokens using the Python Gemini SDK.
  static Future<int> countTokens({
    required String prompt,
    String model = 'gemini-2.5-flash',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;
      
      final idToken = await user.getIdToken();
      if (idToken == null) return 0;

      final response = await http.post(
        Uri.parse(_countTokensUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          "model": model,
          "prompt": prompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['totalTokens'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> pollOperation(String operationName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(_pollOperationUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({"operationName": operationName}),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Poll Operation Failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> generateEmbeddings({
    required String model,
    required List<Map<String, dynamic>> instances,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({"model": model, "instances": instances}),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Embeddings Failed: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> extractStructured({
    required String document,
    required Map<String, dynamic> schema,
    List<Map<String, dynamic>>? examples,
    String model = 'gemini-2.5-flash',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final response = await http.post(
      Uri.parse(_extractStructuredUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        "document": document,
        "schema": schema,
        "examples": examples ?? [],
        "model": model,
      }),
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Extraction Failed: ${response.body}');
    }
  }
}

final aiProxyServiceProvider = Provider<AIProxyService>((ref) => AIProxyService(ref));
