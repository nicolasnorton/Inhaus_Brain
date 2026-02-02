import '../../../core/interfaces/integration_connector.dart';
import '../models/connected_account_model.dart';
import '../models/unified_campaign_model.dart';

class MetaAdsProvider implements AdsConnector {
  @override
  AdPlatform get platform => AdPlatform.metaAds;

  @override
  Future<List<UnifiedCampaign>> getCampaigns(
      ConnectedAccount account, DateTime start, DateTime end) async {
    // START MOCK IMPLEMENTATION
    await Future.delayed(const Duration(seconds: 1));
    return [
      UnifiedCampaign(
        id: 'meta-101',
        connectedAccountId: account.id,
        platform: AdPlatform.metaAds,
        name: 'IG Stories - Awareness',
        status: 'ACTIVE',
        startDate: DateTime(2025, 2, 10),
        spend: 300.00,
        impressions: 45000,
        clicks: 320,
        ctr: 0.007,
        roas: 1.5,
      ),
      UnifiedCampaign(
        id: 'meta-102',
        connectedAccountId: account.id,
        platform: AdPlatform.metaAds,
        name: 'FB Feed - Conversions',
        status: 'ACTIVE',
        startDate: DateTime(2025, 2, 12),
        spend: 850.00,
        impressions: 22000,
        clicks: 410,
        ctr: 0.018,
        roas: 3.2,
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getAccountInsights(
      ConnectedAccount account, DateTime start, DateTime end) async {
    return {
      'totalSpend': 1150.0,
      'frequency': 1.25,
      'reach': 55000,
      'cpm': 9.50,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getAdPerformance(
      ConnectedAccount account, String campaignId, DateTime start, DateTime end) async {
     return [
       {'adId': 'ad-meta-1', 'format': 'Carousel', 'clicks': 200, 'cost': 300.00},
     ]; 
  }

  @override
  Future<ConnectedAccount> validateOrRefreshAuth(ConnectedAccount account) async {
    // Mock token refresh
    return account;
  }
}
