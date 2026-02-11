
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../tokens/llm_provider.dart';

class AIProxyService {
  // TODO: Update this URL after deployment. For local testing, use the emulator URL.
  // Emulator default: http://127.0.0.1:5005/inhausbrain/us-central1/proxyVertexAI
  // Production default: https://us-central1-inhausbrain.cloudfunctions.net/proxyVertexAI
  // Enable Firebase App Check in console for abuse protection
  static String get _functionUrl {
    if (kDebugMode) {
      // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for others
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5005/inhausbrain/us-central1/proxyVertexAI';
      }
      return 'http://127.0.0.1:5005/inhausbrain/us-central1/proxyVertexAI';
    }
    return 'https://us-central1-inhausbrain.cloudfunctions.net/proxyVertexAI';
  }

  static String get _pythonBaseUrl {
    // Note: 2nd Gen Python functions have unique Cloud Run URLs.
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5005/inhausbrain/us-central1';
      }
      return 'http://127.0.0.1:5005/inhausbrain/us-central1';
    }
    // These are the actual 2nd Gen URLs from deployment
    return 'https://generate-content-btdf7nijqa-uc.a.run.app'; 
  }

  static String get _generateImageUrl => kDebugMode ? '$_pythonBaseUrl/generate_image' : 'https://generate-image-btdf7nijqa-uc.a.run.app';
  static String get _generateContentUrl => kDebugMode ? '$_pythonBaseUrl/generate_content' : 'https://generate-content-btdf7nijqa-uc.a.run.app';
  static String get _countTokensUrl => kDebugMode ? '$_pythonBaseUrl/count_tokens' : 'https://count-tokens-btdf7nijqa-uc.a.run.app';
  static String get _liveTokenUrl => kDebugMode ? '$_pythonBaseUrl/get_live_token' : 'https://get-live-token-btdf7nijqa-uc.a.run.app';

  /// Fetch a short-lived access token for the Multimodal Live API.
  Future<Map<String, dynamic>> getLiveToken() async {
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

  static String get _startResearchUrl => kDebugMode ? '$_pythonBaseUrl/start_research' : 'https://start-research-btdf7nijqa-uc.a.run.app';
  static String get _pollResearchUrl => kDebugMode ? '$_pythonBaseUrl/poll_research' : 'https://poll-research-btdf7nijqa-uc.a.run.app';
  static String get _extractStructuredUrl => kDebugMode ? '$_pythonBaseUrl/extract_structured' : 'https://extract-structured-btdf7nijqa-uc.a.run.app';

  /// Routes a generation request through the secure Cloud Function proxy.
  /// 
  /// [prompt] can be a String or a List<Map<String, dynamic>> for multimodal.
  static Future<Map<String, dynamic>> generateContent({
    required dynamic prompt, 
    required AIModelConfig config,
    List<Map<String, dynamic>>? contextData, 
    String? systemInstruction,
    Map<String, dynamic>? generationParams,
    List<Map<String, dynamic>>? tools,
    bool thinking = false,
    bool audio = false,
    bool usePython = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to use AI Proxy.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to retrieve ID Token.');
    }

    // Prepare body
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
    };

    if (usePython) {
      try {
        debugPrint('AIProxyService: 🐍 Routing to Python Gemini SDK (Thinking: $thinking)...');
        final response = await http.post(
          Uri.parse(_generateContentUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 120)); // Longer timeout for complex tasks

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['error'] != null) {
             throw Exception('Python API Error: ${data['error']}');
          }
          return data;
        } else {
          debugPrint('AIProxyService: Python Proxy failed (${response.statusCode}): ${response.body}');
          // Fall through to JS proxy if this was a standard text request
          if (thinking || tools != null || prompt is List) {
             // These features are ONLY in Python, so don't fallback to legacy JS which won't support them
             throw Exception('Python Proxy failed (${response.statusCode}) and features are not available in legacy fallback.');
          }
        }
      } catch (e) {
        debugPrint('AIProxyService Python Error: $e');
        if (thinking || tools != null || prompt is List) rethrow;
        debugPrint('Falling back to legacy JS proxy...');
      }
    }

    // Legacy JS Proxy Fallback
    try {
      debugPrint('AIProxyService: 📦 Routing to Legacy JS Proxy...');
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      );

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
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Unauthenticated');
    final idToken = await user.getIdToken();

    final response = await http.post(
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
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Image Generation Failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Starts a Deep Research task.
  static Future<Map<String, dynamic>> startResearch({
    required String prompt,
    String model = 'gemini-2.0-flash-thinking-exp-01-21',
  }) async {
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
      debugPrint('AIProxyService countTokens Error: $e');
      return 0;
    }
  }


  static Future<Map<String, dynamic>> pollOperation(String operationName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to poll operations.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to retrieve ID Token.');
    }

    final body = {
      "operationName": operationName,
    };

    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
           debugPrint('AIProxyService: ⚠️ Empty response body for polling.');
           return {'done': false}; // Assume still valid or just keep polling
        }
        return jsonDecode(response.body);
      } else {
        throw Exception('Proxy Poll Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e is http.ClientException || e.toString().contains('XMLHttpRequest')) {
        debugPrint('AIProxyService: ⚠️ Network error during poll (likely retriable): $e');
        // Return a "not done" state to force a retry by the caller instead of crashing
        return {'done': false, 'error': 'network_transient'};
      }
      debugPrint('AIProxyService Poll Error: $e');
      rethrow;
    }
  }

  /// Specialized routing for Embeddings with retry logic
  static Future<Map<String, dynamic>> generateEmbeddings({
    required String model,
    required List<Map<String, dynamic>> instances,
  }) async {
    const maxRetries = 2; // Fewer retries for embeddings to keep total time reasonable
    const timeout = Duration(seconds: 60);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User must be logged in to use AI Proxy.');
        }

        final idToken = await user.getIdToken();
        if (idToken == null) {
          throw Exception('Failed to retrieve ID Token.');
        }

        final body = {
          "model": model,
          "instances": instances,
        };

        final response = await http.post(
          Uri.parse(_functionUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(body),
        ).timeout(timeout); // Add explicit timeout

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Proxy Embedding Error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        final isLastAttempt = attempt == maxRetries - 1;
        
        if (isLastAttempt) {
          debugPrint('AIProxyService Embedding Error (Final): $e');
          rethrow;
        }
        
        // Exponential backoff: 1s, 2s
        final delay = Duration(seconds: 1 << attempt);
        debugPrint('AIProxyService Embedding Attempt ${attempt + 1} Failed: $e. Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Embedding generation failed after $maxRetries attempts');
  }

  /// Routes a structured extraction request to the specialized Python LangExtract function.
  static Future<Map<String, dynamic>> extractStructured({
    required String document,
    required Map<String, dynamic> schema,
    List<Map<String, dynamic>>? examples,
    String model = 'gemini-2.5-flash',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to use extraction services.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to retrieve ID Token.');
    }

    final extractFunctionUrl = _extractStructuredUrl;

    final body = {
      "document": document,
      "schema": schema,
      "examples": examples ?? [],
      "model": model,
    };

    try {
      final response = await http.post(
        Uri.parse(extractFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 120)); // Extraction can take longer

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Extraction Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('AIProxyService Extraction Error: $e');
      rethrow;
    }
  }
}

