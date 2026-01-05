import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campaign.dart';
import '../../../core/services/firebase_service_provider.dart';

class CampaignListNotifier extends Notifier<List<Campaign>> {
  @override
  List<Campaign> build() {
    final firebaseService = ref.watch(firebaseServiceProvider);
    
    // Listen to Firestore stream and update state
    firebaseService.watchCampaigns().listen((campaigns) {
      state = campaigns;
    });

    return [];
  }

  Future<void> addCampaign(Campaign campaign) async {
    await ref.read(firebaseServiceProvider).saveCampaign(campaign);
  }

  Future<void> updateCampaign(Campaign campaign) async {
    await ref.read(firebaseServiceProvider).updateCampaign(campaign);
  }
}

final campaignListProvider = NotifierProvider<CampaignListNotifier, List<Campaign>>(CampaignListNotifier.new);
