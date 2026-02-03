import '../../features/connectors/models/connected_account_model.dart';
import '../../features/connectors/models/unified_campaign_model.dart';
import '../../features/connectors/models/post_model.dart'; // Will create this

/// Base interface for all platform connectors
abstract class BaseConnector {
  AdPlatform get platform;

  /// Initiate the OAuth connection flow (Platform specific implementation)
  Future<ConnectedAccount?> connect(String clientId);

  /// Validate the authentication token. Refresh if necessary.
  /// Returns the updated account (with new token) or throws exception if auth invalid.
  Future<ConnectedAccount> validateOrRefreshAuth(ConnectedAccount account);

  /// Fetch broad-level insights/metrics for constraints
  Future<Map<String, dynamic>> getAccountInsights(
    ConnectedAccount account,
    DateTime start, 
    DateTime end
  );
}

/// Interface for Paid Media platforms (Google Ads, Meta Ads, etc.)
abstract class AdsConnector extends BaseConnector {
  Future<List<UnifiedCampaign>> getCampaigns(
    ConnectedAccount account, 
    DateTime start, 
    DateTime end
  );
  
  /// Get specific ad group or ad level performance if needed
  Future<List<Map<String, dynamic>>> getAdPerformance(
    ConnectedAccount account,
    String campaignId,
    DateTime start,
    DateTime end
  );
}

/// Interface for Social Organic platforms (Instagram, TikTok, LinkedIn, etc.)
abstract class SocialConnector extends BaseConnector {
  Future<List<UnifiedPost>> getPosts(
    ConnectedAccount account,
    DateTime start,
    DateTime end
  );
  
  Future<Map<String, dynamic>> getFollowerGrowth(
    ConnectedAccount account,
    DateTime start,
    DateTime end
  );
}

/// Interface for Analytics platforms (GA4, Search Console)
abstract class AnalyticsConnector extends BaseConnector {
  Future<Map<String, dynamic>> getCustomReport(
    ConnectedAccount account,
    List<String> dimensions,
    List<String> metrics,
    DateTime start,
    DateTime end
  );
}
