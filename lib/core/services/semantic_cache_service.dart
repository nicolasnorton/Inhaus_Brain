import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';
import '../tokens/llm_provider.dart';
import 'edge_ai_service.dart';

/// Semantic Cache Service to reduce AI cost and latency.
/// 
/// It stores prompt:response pairs in Firestore.
/// Keys are SHA-256 hashes of the prompt + model config.
/// Scoped to the User to prevent data leakage.
class SemanticCacheService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SemanticCacheService(this._ref);

  /// Generates a unique cache key based on prompt and model headers
  String _generateKey(String prompt, AIModelConfig config) {
    final payload = "${config.modelId}:${config.temperature}:$prompt";
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Attempts to retrieve a cached response.
  /// Supports:
  /// 1. (String prompt, AIModelConfig config) -> EdgeAIResult?
  /// 2. (String label, String key) -> String?
  Future<dynamic> lookup(dynamic promptOrLabel, dynamic configOrKey) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return null;

    String key;
    bool isAiResult = false;

    if (configOrKey is AIModelConfig) {
      if (configOrKey.temperature > 0.9) return null;
      key = _generateKey(promptOrLabel as String, configOrKey);
      isAiResult = true;
    } else if (configOrKey is String) {
      final rawKey = "generic:${promptOrLabel}:$configOrKey";
      if (rawKey.length > 1000) {
        final bytes = utf8.encode(rawKey);
        final digest = sha256.convert(bytes);
        key = "hashed:${digest.toString()}";
      } else {
        key = rawKey;
      }
      isAiResult = false;
    } else {
      return null;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cache')
          .doc(key)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        debugPrint('SemanticCache: HIT ($key)');
        
        if (isAiResult) {
          return EdgeAIResult(
            data['text'] as String,
            AIProximity.local,
            modelUsed: "${data['modelId']} (Cached)",
            confidence: (data['confidence'] as num?)?.toDouble() ?? 1.0,
            sourceCitations: (data['citations'] as List?)?.map((e) => e.toString()).toList(),
          );
        } else {
          return data['text'] as String;
        }
      }
    } catch (e) {
      debugPrint('SemanticCache: Read Error: $e');
    }
    
    return null;
  }

  /// Alias for lookup (backward compatibility)
  Future<EdgeAIResult?> get(String prompt, AIModelConfig config) async {
    final res = await lookup(prompt, config);
    return res is EdgeAIResult ? res : null;
  }

  /// Saves a value to the cache.
  /// Supports:
  /// 1. (String prompt, AIModelConfig config, EdgeAIResult result)
  /// 2. (String label, String key, String resultText)
  Future<void> store(dynamic promptOrLabel, dynamic configOrKey, dynamic resultOrText) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    
    String key;
    Map<String, dynamic> payload = {
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (configOrKey is AIModelConfig && resultOrText is EdgeAIResult) {
      if (configOrKey.temperature > 0.9) return;
      if (resultOrText.text.isEmpty) return;
      key = _generateKey(promptOrLabel as String, configOrKey);
      payload.addAll({
        'text': resultOrText.text,
        'modelId': configOrKey.modelId,
        'confidence': resultOrText.confidence,
        'citations': resultOrText.sourceCitations ?? [],
        'promptPreview': (promptOrLabel as String).length > 50 ? promptOrLabel.substring(0, 50) : promptOrLabel,
      });
    } else if (configOrKey is String && resultOrText is String) {
      final rawKey = "generic:${promptOrLabel}:$configOrKey";
      // Firestore document ID limit is 1500 bytes. 
      // If the generated key is too long, hash it.
      if (rawKey.length > 1000) {
        final bytes = utf8.encode(rawKey);
        final digest = sha256.convert(bytes);
        key = "hashed:${digest.toString()}";
      } else {
        key = rawKey;
      }
      
      payload.addAll({
        'text': resultOrText,
        'label': promptOrLabel,
        'key': configOrKey,
      });
    } else {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cache')
          .doc(key)
          .set(payload);
          
      debugPrint('SemanticCache: Saved ($key)');
    } catch (e) {
      debugPrint('SemanticCache: Write Error: $e');
    }
  }

  /// Clears the entire cache for the current user.
  Future<void> clearCache() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      final docs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cache')
          .get();
      
      final batch = _firestore.batch();
      for (var doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('SemanticCache: 🛡️ Cache cleared for user ${user.uid}');
    } catch (e) {
      debugPrint('SemanticCache: Clear Error: $e');
    }
  }

  /// Alias for store (backward compatibility)
  Future<void> set(String prompt, AIModelConfig config, EdgeAIResult result) async {
    return store(prompt, config, result);
  }
}

final semanticCacheServiceProvider = Provider<SemanticCacheService>((ref) {
  return SemanticCacheService(ref);
});
