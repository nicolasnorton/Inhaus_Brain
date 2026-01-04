import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campaign.dart';

class CampaignListNotifier extends Notifier<List<Campaign>> {
  @override
  List<Campaign> build() => [];

  void addCampaign(Campaign campaign) {
    state = [...state, campaign];
  }

  void updateCampaign(Campaign campaign) {
    state = [
      for (final item in state)
        if (item.id == campaign.id) campaign else item
    ];
  }
}

final campaignListProvider = NotifierProvider<CampaignListNotifier, List<Campaign>>(CampaignListNotifier.new);
