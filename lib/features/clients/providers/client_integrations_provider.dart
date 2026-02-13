import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/oauth_service.dart';

class ClientIntegrationState {
  // Productivity
  final bool isGmailConnected;
  final bool isSlackConnected;
  final bool isNotionConnected;
  final bool isGHLConnected;

  // Ads
  final bool isGoogleAdsConnected;
  final bool isMetaAdsConnected;
  final bool isTikTokAdsConnected;
  final bool isXAdsConnected;
  final bool isLinkedInAdsConnected;
  final bool isPinterestAdsConnected;
  final bool isAppleSearchAdsConnected;

  // Analytics
  final bool isGA4Connected;
  final bool isSearchConsoleConnected;
  final bool isGoogleBusinessConnected;

  // Social
  final bool isMetaOrganicConnected;
  final bool isTikTokOrganicConnected;

  ClientIntegrationState({
    this.isGmailConnected = false,
    this.isSlackConnected = false,
    this.isNotionConnected = false,
    this.isGHLConnected = false,
    this.isGoogleAdsConnected = false,
    this.isMetaAdsConnected = false,
    this.isTikTokAdsConnected = false,
    this.isXAdsConnected = false,
    this.isLinkedInAdsConnected = false,
    this.isPinterestAdsConnected = false,
    this.isAppleSearchAdsConnected = false,
    this.isGA4Connected = false,
    this.isSearchConsoleConnected = false,
    this.isGoogleBusinessConnected = false,
    this.isMetaOrganicConnected = false,
    this.isTikTokOrganicConnected = false,
  });

  ClientIntegrationState copyWith({
    bool? isGmailConnected,
    bool? isSlackConnected,
    bool? isNotionConnected,
    bool? isGHLConnected,
    bool? isGoogleAdsConnected,
    bool? isMetaAdsConnected,
    bool? isTikTokAdsConnected,
    bool? isXAdsConnected,
    bool? isLinkedInAdsConnected,
    bool? isPinterestAdsConnected,
    bool? isAppleSearchAdsConnected,
    bool? isGA4Connected,
    bool? isSearchConsoleConnected,
    bool? isGoogleBusinessConnected,
    bool? isMetaOrganicConnected,
    bool? isTikTokOrganicConnected,
  }) {
    return ClientIntegrationState(
      isGmailConnected: isGmailConnected ?? this.isGmailConnected,
      isSlackConnected: isSlackConnected ?? this.isSlackConnected,
      isNotionConnected: isNotionConnected ?? this.isNotionConnected,
      isGHLConnected: isGHLConnected ?? this.isGHLConnected,
      isGoogleAdsConnected: isGoogleAdsConnected ?? this.isGoogleAdsConnected,
      isMetaAdsConnected: isMetaAdsConnected ?? this.isMetaAdsConnected,
      isTikTokAdsConnected: isTikTokAdsConnected ?? this.isTikTokAdsConnected,
      isXAdsConnected: isXAdsConnected ?? this.isXAdsConnected,
      isLinkedInAdsConnected: isLinkedInAdsConnected ?? this.isLinkedInAdsConnected,
      isPinterestAdsConnected: isPinterestAdsConnected ?? this.isPinterestAdsConnected,
      isAppleSearchAdsConnected: isAppleSearchAdsConnected ?? this.isAppleSearchAdsConnected,
      isGA4Connected: isGA4Connected ?? this.isGA4Connected,
      isSearchConsoleConnected: isSearchConsoleConnected ?? this.isSearchConsoleConnected,
      isGoogleBusinessConnected: isGoogleBusinessConnected ?? this.isGoogleBusinessConnected,
      isMetaOrganicConnected: isMetaOrganicConnected ?? this.isMetaOrganicConnected,
      isTikTokOrganicConnected: isTikTokOrganicConnected ?? this.isTikTokOrganicConnected,
    );
  }
}


class ClientIntegrationsNotifier extends StateNotifier<Map<String, ClientIntegrationState>> {
  ClientIntegrationsNotifier() : super({});

  Future<void> handleToggle(String clientId, String provider, bool status) async {
    // If turning OFF, just update state
    if (!status) {
      toggleIntegration(clientId, provider, false);
      return;
    }

    // If turning ON, trigger OAuth flow for specific providers
    String? token;
    
    if (provider == 'Google Ads') {
      token = await OAuthService.authorize(OAuthProvider.googleAds);
    } else if (provider == 'Google Analytics 4') {
      token = await OAuthService.authorize(OAuthProvider.googleAnalytics);
    } else if (provider == 'Meta Ads') {
       token = await OAuthService.authorize(OAuthProvider.metaAds);
    } else if (provider == 'TikTok Ads') {
       token = await OAuthService.authorize(OAuthProvider.tiktokAds);
    } else if (provider == 'LinkedIn Ads') {
       token = await OAuthService.authorize(OAuthProvider.linkedinAds);
    } else {
      // Default for non-OAuth platforms or others
      token = "mock_token";
    }

    if (token != null) {
      toggleIntegration(clientId, provider, true);
    }
  }

  void toggleIntegration(String clientId, String provider, bool status) {
    final current = state[clientId] ?? ClientIntegrationState();
    final updated = switch (provider) {
      'Gmail' => current.copyWith(isGmailConnected: status),
      'Slack' => current.copyWith(isSlackConnected: status),
      'Notion' => current.copyWith(isNotionConnected: status),
      'GoHighLevel' => current.copyWith(isGHLConnected: status),
      'Google Ads' => current.copyWith(isGoogleAdsConnected: status),
      'Meta Ads' => current.copyWith(isMetaAdsConnected: status),
      'TikTok Ads' => current.copyWith(isTikTokAdsConnected: status),
      'X Ads' => current.copyWith(isXAdsConnected: status),
      'LinkedIn Ads' => current.copyWith(isLinkedInAdsConnected: status),
      'Pinterest Ads' => current.copyWith(isPinterestAdsConnected: status),
      'Apple Search Ads' => current.copyWith(isAppleSearchAdsConnected: status),
      'Google Analytics 4' => current.copyWith(isGA4Connected: status),
      'Search Console' => current.copyWith(isSearchConsoleConnected: status),
      'Google Business' => current.copyWith(isGoogleBusinessConnected: status),
      'Meta Organic' => current.copyWith(isMetaOrganicConnected: status),
      'TikTok Organic' => current.copyWith(isTikTokOrganicConnected: status),
      _ => current,
    };

    final newState = Map<String, ClientIntegrationState>.from(state);
    newState[clientId] = updated;
    state = newState;
  }

  ClientIntegrationState getIntegrationsForClient(String clientId) {
    return state[clientId] ?? ClientIntegrationState();
  }
}

final clientIntegrationsProvider = StateNotifierProvider<ClientIntegrationsNotifier, Map<String, ClientIntegrationState>>((ref) => ClientIntegrationsNotifier());
