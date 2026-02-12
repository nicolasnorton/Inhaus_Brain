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

  /// TTL for cached entries (24 hours)
  static const Duration cacheTtl = Duration(hours: 24);

  /// In-memory LRU cache (avoids Firestore reads for hot prompts)
  static const int _maxLruSize = 100;
  final Map<String, _LruEntry> _lruCache = {};
  final List<String> _lruOrder = [];  // Most recently used at end

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

    // ── LRU check first (avoids Firestore read) ──
    final lruHit = _lruGet(key);
    if (lruHit != null) {
      if (_isExpired(lruHit.timestamp)) {
        _lruRemove(key);
      } else {
        debugPrint('SemanticCache: LRU HIT ($key)');
        return isAiResult ? lruHit.toEdgeAIResult() : lruHit.text;
      }
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

        // ── TTL check ──
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null && _isExpired(createdAt)) {
          debugPrint('SemanticCache: TTL EXPIRED ($key)');
          // Fire-and-forget delete
          doc.reference.delete().catchError((_) {});
          return null;
        }

        debugPrint('SemanticCache: Firestore HIT ($key)');

        // Promote to LRU
        final entry = _LruEntry(
          text: data['text'] as String,
          modelId: data['modelId'] as String? ?? 'unknown',
          confidence: (data['confidence'] as num?)?.toDouble() ?? 1.0,
          citations: (data['citations'] as List?)?.map((e) => e.toString()).toList(),
          timestamp: createdAt ?? DateTime.now(),
        );
        _lruPut(key, entry);

        if (isAiResult) {
          return entry.toEdgeAIResult();
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

    // Clear in-memory LRU
    _lruCache.clear();
    _lruOrder.clear();

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

  // ── LRU Helpers ──────────────────────────────────────────

  bool _isExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp) > cacheTtl;
  }

  _LruEntry? _lruGet(String key) {
    final entry = _lruCache[key];
    if (entry != null) {
      // Move to end (most recently used)
      _lruOrder.remove(key);
      _lruOrder.add(key);
    }
    return entry;
  }

  void _lruPut(String key, _LruEntry entry) {
    if (_lruCache.containsKey(key)) {
      _lruOrder.remove(key);
    } else if (_lruCache.length >= _maxLruSize) {
      // Evict least recently used
      final evictKey = _lruOrder.removeAt(0);
      _lruCache.remove(evictKey);
    }
    _lruCache[key] = entry;
    _lruOrder.add(key);
  }

  void _lruRemove(String key) {
    _lruCache.remove(key);
    _lruOrder.remove(key);
  }
}

/// Internal LRU cache entry.
class _LruEntry {
  final String text;
  final String modelId;
  final double confidence;
  final List<String>? citations;
  final DateTime timestamp;

  _LruEntry({
    required this.text,
    required this.modelId,
    this.confidence = 1.0,
    this.citations,
    required this.timestamp,
  });

  EdgeAIResult toEdgeAIResult() => EdgeAIResult(
    text,
    AIProximity.local,
    modelUsed: '$modelId (Cached)',
    confidence: confidence,
    sourceCitations: citations,
  );
}

final semanticCacheServiceProvider = Provider<SemanticCacheService>((ref) {
  return SemanticCacheService(ref);
});
