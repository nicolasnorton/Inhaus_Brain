import '../../../core/interfaces/integration_connector.dart';
import '../models/connected_account_model.dart';
import '../models/unified_campaign_model.dart';

class GoogleAdsProvider implements AdsConnector {
  @override
  AdPlatform get platform => AdPlatform.googleAds;

  @override
  Future<List<UnifiedCampaign>> getCampaigns(
      ConnectedAccount account, DateTime start, DateTime end) async {
    // START MOCK IMPLEMENTATION
    await Future.delayed(const Duration(seconds: 1));
    return [
      UnifiedCampaign(
        id: '12345',
        connectedAccountId: account.id,
        platform: AdPlatform.googleAds,
        name: 'Search - Brand Defense',
        status: 'ENABLED',
        startDate: DateTime(2025, 1, 1),
        spend: 1250.00,
        impressions: 15000,
        clicks: 450,
        ctr: 0.03,
        roas: 4.5,
      ),
      UnifiedCampaign(
        id: '67890',
        connectedAccountId: account.id,
        platform: AdPlatform.googleAds,
        name: 'Display - Retargeting',
        status: 'PAUSED',
        startDate: DateTime(2025, 2, 1),
        spend: 500.00,
        impressions: 50000,
        clicks: 200,
        ctr: 0.004,
        roas: 2.1,
      ),
    ];
    // END MOCK IMPLEMENTATION
  }

  @override
  Future<Map<String, dynamic>> getAccountInsights(
      ConnectedAccount account, DateTime start, DateTime end) async {
    return {
      'totalSpend': 1750.0,
      'totalConversions': 55,
      'topKeywords': ['inhaus brain', 'ai marketing', 'automation'],
      'optimizationScore': 0.85,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getAdPerformance(
      ConnectedAccount account, String campaignId, DateTime start, DateTime end) async {
     return [
       {'adId': 'ad-1', 'headline': 'Best AI Tool', 'clicks': 120, 'cost': 150.00},
       {'adId': 'ad-2', 'headline': 'Automate Reports', 'clicks': 95, 'cost': 110.00},
     ]; 
  }

  @override
  Future<ConnectedAccount> validateOrRefreshAuth(ConnectedAccount account) async {
    // In real implementation: Check expiry, call OAuth refresh endpoint if needed
    // Return potentially updated account object (with new token)
    return account;
  }
}
