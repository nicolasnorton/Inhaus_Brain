import '../../../core/interfaces/integration_connector.dart';
import '../models/connected_account_model.dart';
import '../models/post_model.dart';

class GenericSocialProvider implements SocialConnector {
  final AdPlatform _platform;

  GenericSocialProvider(this._platform);

  @override
  AdPlatform get platform => _platform;

  @override
  Future<ConnectedAccount?> connect(String clientId) async {
    // TODO: Implement generic OAuth or manual token entry
    return null;
  }

  @override
  Future<List<UnifiedPost>> getPosts(
      ConnectedAccount account, DateTime start, DateTime end) async {
    // START MOCK
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Return dummy posts based on platform
    return [
      UnifiedPost(
        id: '${_platform.name}-post-1',
        connectedAccountId: account.id,
        platform: _platform,
        caption: 'Exciting news coming soon! #${_platform.name} #Inhaus',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        likes: 120,
        comments: 15,
        shares: 5,
        impressions: 1500,
        engagementRate: 0.09,
      ),
      UnifiedPost(
        id: '${_platform.name}-post-2',
        connectedAccountId: account.id,
        platform: _platform,
        caption: 'Check out our new feature drop via ${_platform.name}.',
        publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        likes: 340,
        comments: 45,
        shares: 20,
        impressions: 4500,
        engagementRate: 0.12,
      )
    ];
  }

  @override
  Future<Map<String, dynamic>> getFollowerGrowth(
      ConnectedAccount account, DateTime start, DateTime end) async {
    return {
      'totalFollowers': 15400,
      'newFollowers': 230,
      'growthRate': 0.015,
    };
  }
  
  @override
  Future<Map<String, dynamic>> getAccountInsights(ConnectedAccount account, DateTime start, DateTime end) async {
    return {
      'avgEngagementRate': 0.10,
      'contentInteractions': 4500,
      'accountsReached': 12000,
    };
  }

  @override
  Future<ConnectedAccount> validateOrRefreshAuth(ConnectedAccount account) async {
    return account;
  }
}
