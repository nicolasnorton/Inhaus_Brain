
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/connectors/models/connected_account_model.dart';
import '../../features/connectors/models/unified_campaign_model.dart';
import '../interfaces/ad_platform_provider.dart';
// Implementations would be imported here
import '../../features/connectors/providers/google_ads_provider.dart';

class AdPlatformsService {
  final Map<AdPlatform, AdPlatformProvider> _providers = {};

  AdPlatformsService() {
    registerProvider(AdPlatform.googleAds, GoogleAdsProvider());
    // Register others...
  }

  void registerProvider(AdPlatform platform, AdPlatformProvider provider) {
    _providers[platform] = provider;
  }

  Future<List<UnifiedCampaign>> getCampaignsForAccount(
      ConnectedAccount account, DateTime start, DateTime end) async {
    final provider = _providers[account.platform];
    if (provider == null) {
      // Return empty or throw error if provider not found
      print('Warning: No provider registered for ${account.platform}');
      return [];
    }
    
    // Validate auth first
    // final validAccount = await provider.validateOrRefreshAuth(account); 
    // If refreshed, save back to Firestore? Requires reference to ConnectedAccountsService here.
    
    return await provider.getCampaigns(account, start, end);
  }
}

final adPlatformsServiceProvider = Provider<AdPlatformsService>((ref) {
  return AdPlatformsService();
});
