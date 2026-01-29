
import '../features/connectors/models/connected_account_model.dart';
import '../features/connectors/models/unified_campaign_model.dart';

/// Abstract base class for all Ad Platform Providers
abstract class AdPlatformProvider {
  AdPlatform get platform;

  /// Fetch campaigns for a given account within a date range
  Future<List<UnifiedCampaign>> getCampaigns(
    ConnectedAccount account, 
    DateTime start, 
    DateTime end
  );

  /// Fetch insights/metrics (can be more detailed than campaign list)
  Future<Map<String, dynamic>> getInsights(
    ConnectedAccount account,
    DateTime start, 
    DateTime end
  );

  /// Check if the token is valid, refresh if needed
  Future<ConnectedAccount> validateOrRefreshAuth(ConnectedAccount account);
}
