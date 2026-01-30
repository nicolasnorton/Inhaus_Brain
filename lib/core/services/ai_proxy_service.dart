
import 'dart:convert';
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
      // Use IPv4 loopback to avoid IPv6 resolution issues on macOS
      return 'http://127.0.0.1:5005/inhausbrain/us-central1/proxyVertexAI';
    }
    return 'https://us-central1-inhausbrain.cloudfunctions.net/proxyVertexAI';
  }  

  /// Routes a generation request through the secure Cloud Function proxy.
  /// 
  /// [prompt] can be a String or a complex structure depending on the backend expectation.
  /// For this implementation, we send the prompt and config to the proxy.
  static Future<Map<String, dynamic>> generateContent({
    required String prompt,
    required AIModelConfig config,
    List<Map<String, dynamic>>? contextData, // Future use for structured context
    String? systemInstruction,
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
      "config": {
        "temperature": config.temperature,
        "maxOutputTokens": config.maxTokens,
        if (config.responseMimeType != null) "responseMimeType": config.responseMimeType,
      },
      if (systemInstruction != null) "systemInstruction": systemInstruction, 
    };

    try {
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
      debugPrint('AIProxyService Error: $e');
      rethrow;
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
      );

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
}
