import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campaign.dart';
import '../../../core/services/firebase_service_provider.dart';
import '../../../core/auth/auth_service.dart';

class CampaignListNotifier extends Notifier<List<Campaign>> {
  @override
  List<Campaign> build() {
    final firebaseService = ref.watch(firebaseServiceProvider);
    final authService = ref.watch(authServiceProvider);
    final userClientId = authService.userClientId;
    final isAdmin = authService.isAdmin;
    
    // Listen to Firestore stream and update state
    firebaseService.watchCampaigns().listen((campaigns) {
      if (isAdmin) {
        state = campaigns;
      } else if (userClientId != null) {
        state = campaigns.where((c) => c.clientId == userClientId).toList();
      } else {
        state = []; // No access if not admin and no clientId
      }
    });

    return [];
  }

  Future<void> addCampaign(Campaign campaign) async {
    await ref.read(firebaseServiceProvider).saveCampaign(campaign);
  }

  Future<void> updateCampaign(Campaign campaign) async {
    await ref.read(firebaseServiceProvider).updateCampaign(campaign);
  }

  Future<void> deleteCampaign(String campaignId) async {
    await ref.read(firebaseServiceProvider).deleteCampaign(campaignId);
  }
}

final campaignListProvider = NotifierProvider<CampaignListNotifier, List<Campaign>>(CampaignListNotifier.new);
