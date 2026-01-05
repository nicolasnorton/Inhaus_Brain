import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/campaigns/models/campaign.dart';
import 'edge_ai_service.dart';

abstract class FirebaseService {
  Stream<List<Campaign>> watchCampaigns();
  Future<void> saveCampaign(Campaign campaign);
  Future<void> updateCampaign(Campaign campaign);
  Future<String> triggerAiResearch(String campaignId, String prompt);
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
      print('Firebase Function Error: $e');
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
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      _mockCampaigns = decoded.map((item) => Campaign.fromJson(item as Map<String, dynamic>)).toList();
    }
    _campaignsController.add(List.from(_mockCampaigns));
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_mockCampaigns.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, data);
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
    return EdgeAIService.generateText(prompt);
  }
}

