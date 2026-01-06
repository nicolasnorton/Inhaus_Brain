import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/campaigns/models/campaign.dart';
import 'edge_ai_service.dart';

abstract class FirebaseService {
  Stream<List<Campaign>> watchCampaigns();
  Future<void> saveCampaign(Campaign campaign);
  Future<void> updateCampaign(Campaign campaign);
  Future<String> triggerAiResearch(String campaignId, String prompt);
  
  // High-Tier generation for final assets
  Future<Map<String, dynamic>> generateFinalAssets({
    required String campaignId,
    required String creativeBrief,
    required String visualPrompt,
  });
}

class ProdFirebaseService implements FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Stream<List<Campaign>> watchCampaigns() {
    return _firestore
        .collection('campaigns')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Campaign.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  @override
  Future<void> saveCampaign(Campaign campaign) async {
    await _firestore
        .collection('campaigns')
        .doc(campaign.id)
        .set(campaign.toJson());
  }

  @override
  Future<void> updateCampaign(Campaign campaign) async {
    await _firestore
        .collection('campaigns')
        .doc(campaign.id)
        .update(campaign.toJson());
  }

  @override
  Future<String> triggerAiResearch(String campaignId, String prompt) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('generateResearch');
      final result = await callable.call({
        'campaignId': campaignId,
        'prompt': prompt,
      });
      return result.data['result'] as String;
    } catch (e) {
      debugPrint('Firebase Function Error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> generateFinalAssets({
    required String campaignId,
    required String creativeBrief,
    required String visualPrompt,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('generateFinalAssets');
      final result = await callable.call({
        'campaignId': campaignId,
        'creativeBrief': creativeBrief,
        'visualPrompt': visualPrompt,
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Firebase Function (Final Assets) Error: $e');
      rethrow;
    }
  }
}

class MockFirebaseService implements FirebaseService {
  final _campaignsController = StreamController<List<Campaign>>.broadcast();
  List<Campaign> _mockCampaigns = [];
  static const _storageKey = 'inhaus_campaigns';

  MockFirebaseService() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _mockCampaigns = decoded.map((item) => Campaign.fromJson(item as Map<String, dynamic>)).toList();
        debugPrint('MockFirebase: Loaded ${_mockCampaigns.length} campaigns from storage.');
      } else {
        // Initial Mock Data
        _mockCampaigns = [
          Campaign(
            id: 'camp-1',
            title: 'Coffee Revolution',
            description: 'Organic coffee brand launch',
            clientId: 'client-1',
            clientName: 'Inhaus Studios',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          Campaign(
            id: 'camp-2',
            title: 'Sustainable Packaging',
            description: 'Recycled materials campaign',
            clientId: 'client-1',
            clientName: 'Inhaus Studios',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          Campaign(
            id: 'camp-3',
            title: 'AI Tech Summit',
            description: 'Global reach for tech events',
            clientId: 'client-2',
            clientName: 'Global Tech Corp',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        await _saveToStorage();
      }
      _campaignsController.add(List.from(_mockCampaigns));
    } catch (e) {
      debugPrint('MockFirebase ERROR: Failed to load from storage: $e');
      _campaignsController.add([]);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_mockCampaigns.map((c) => c.toJson()).toList());
      await prefs.setString(_storageKey, data);
      debugPrint('MockFirebase: Saved ${_mockCampaigns.length} campaigns to storage.');
    } catch (e) {
      debugPrint('MockFirebase ERROR: Failed to save to storage: $e');
    }
  }

  @override
  Stream<List<Campaign>> watchCampaigns() => _campaignsController.stream;

  @override
  Future<void> saveCampaign(Campaign campaign) async {
    _mockCampaigns.add(campaign);
    _campaignsController.add(List.from(_mockCampaigns));
    await _saveToStorage();
  }

  @override
  Future<void> updateCampaign(Campaign campaign) async {
    final index = _mockCampaigns.indexWhere((c) => c.id == campaign.id);
    if (index != -1) {
      _mockCampaigns[index] = campaign;
      _campaignsController.add(List.from(_mockCampaigns));
      await _saveToStorage();
    }
  }

  @override
  Future<String> triggerAiResearch(String campaignId, String prompt) async {
    final result = await EdgeAIService.generateText(prompt);
    return result.text;
  }

  @override
  Future<Map<String, dynamic>> generateFinalAssets({
    required String campaignId,
    required String creativeBrief,
    required String visualPrompt,
  }) async {
    await Future.delayed(const Duration(seconds: 3)); // Simulating Cloud Generation
    return {
      'status': 'success',
      'finalCopy': 'PRO MOCK: Experience true sustainability with our recycled ocean plastic range. Durable, stylish, and ethical.',
      'finalImageURL': 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?q=80&w=2070&auto=format&fit=crop',
      'source': 'Mock Vertex AI'
    };
  }
}

