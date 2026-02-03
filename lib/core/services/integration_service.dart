import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/connectors/models/connected_account_model.dart';
import '../../features/connectors/models/unified_campaign_model.dart';
import '../../features/connectors/models/post_model.dart';
import '../interfaces/integration_connector.dart';

// Import providers
import '../../features/connectors/providers/google_ads_provider.dart';
import '../../features/connectors/providers/meta_ads_provider.dart';
import '../../features/connectors/providers/generic_social_provider.dart';
import '../../features/connectors/providers/google_analytics_provider.dart';

class IntegrationService {
  final Map<AdPlatform, BaseConnector> _connectors = {};

  IntegrationService() {
    // Register Ads
    registerConnector(AdPlatform.googleAds, GoogleAdsProvider()); 
    registerConnector(AdPlatform.metaAds, MetaAdsProvider());
    
    // Register Social Organic
    final fbK = GenericSocialProvider(AdPlatform.facebookOrganic);
    final igK = GenericSocialProvider(AdPlatform.instagramOrganic);
    final liK = GenericSocialProvider(AdPlatform.linkedinOrganic);
    final ttK = GenericSocialProvider(AdPlatform.tiktokOrganic);
    
    registerConnector(AdPlatform.facebookOrganic, fbK);
    registerConnector(AdPlatform.instagramOrganic, igK);
    registerConnector(AdPlatform.linkedinOrganic, liK);
    registerConnector(AdPlatform.tiktokOrganic, ttK);

    // Register Analytics
    registerConnector(AdPlatform.googleAnalytics, GoogleAnalyticsProvider());
  }

  void registerConnector(AdPlatform platform, BaseConnector connector) {
    _connectors[platform] = connector;
  }
  
  BaseConnector? _getConnector(AdPlatform platform) => _connectors[platform];

  /// Initiate a new connection (Oauth Flow)
  Future<ConnectedAccount?> initiateConnection(AdPlatform platform, String clientId) async {
    final connector = _getConnector(platform);
    if (connector == null) {
      throw Exception('No connector found for platform: $platform');
    }
    return await connector.connect(clientId);
  }

  /// Core Method: Pull Data based on Account Type
  Future<Map<String, dynamic>> syncDataForAccount(
      ConnectedAccount account, DateTime start, DateTime end) async {
    
    final connector = _getConnector(account.platform);
    if (connector == null) {
      throw Exception('No connector found for platform: ${account.platform}');
    }

    // 1. Auth Check
    final validAccount = await connector.validateOrRefreshAuth(account);
    // TODO: If updated, save [validAccount] to Firestore via a callback or repo
    
    final results = <String, dynamic>{
      'syncedAt': DateTime.now().toIso8601String(),
    };

    // 2. Fetch specific data based on interface type
    if (connector is AdsConnector) {
      final campaigns = await connector.getCampaigns(validAccount, start, end);
      results['campaigns'] = campaigns.map((c) => c.toJson()).toList();
      results['type'] = 'ads';
    } 
    else if (connector is SocialConnector) {
      final posts = await connector.getPosts(validAccount, start, end);
      final followers = await connector.getFollowerGrowth(validAccount, start, end);
      results['posts'] = posts.map((p) => p.toJson()).toList();
      results['followers'] = followers;
      results['type'] = 'social';
    }
    else if (connector is AnalyticsConnector) {
       // Default standard report for analytics
       final report = await connector.getCustomReport(
         validAccount, 
         ['date'], 
         ['activeUsers', 'screenPageViews', 'conversions'], 
         start, 
         end
       );
       results['report'] = report;
       results['type'] = 'analytics';
    }

    // 3. Common Insights
    try {
      final insights = await connector.getAccountInsights(validAccount, start, end);
      results['insights'] = insights;
    } catch (e) {
      print('Failed to fetch insights for ${account.accountName}: $e');
    }

    return results;
  }
  Future<List<UnifiedCampaign>> getCampaigns(ConnectedAccount account, DateTime start, DateTime end) async {
    final connector = _getConnector(account.platform);
    if (connector is AdsConnector) {
      // Validate auth first
      final validAccount = await connector.validateOrRefreshAuth(account);
      return await connector.getCampaigns(validAccount, start, end);
    }
    return [];
  }
}


final integrationServiceProvider = Provider<IntegrationService>((ref) {
  return IntegrationService();
});
