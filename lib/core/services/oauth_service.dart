import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

enum OAuthProvider {
  googleAds,
  metaAds,
  googleAnalytics,
  tiktokAds,
  linkedinAds,
}

class OAuthService {
  static final GoogleSignIn _googleAdsSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/adwords',
    ],
  );

  static final GoogleSignIn _googleAnalyticsSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/analytics.readonly',
      'https://www.googleapis.com/auth/analytics.edit',
    ],
  );

  /// Triggers OAuth flow for a specific provider.
  /// Returns the access token (mocked or real) or null if canceled.
  static Future<String?> authorize(OAuthProvider provider) async {
    switch (provider) {
      case OAuthProvider.googleAds:
        return _authorizeGoogle(_googleAdsSignIn);
      case OAuthProvider.googleAnalytics:
        return _authorizeGoogle(_googleAnalyticsSignIn);
      case OAuthProvider.metaAds:
        return _mockOAuthFlow("Meta Ads");
      case OAuthProvider.tiktokAds:
        return _mockOAuthFlow("TikTok Ads");
      case OAuthProvider.linkedinAds:
        return _mockOAuthFlow("LinkedIn Ads");
      default:
        return null;
    }
  }

  static Future<String?> _authorizeGoogle(GoogleSignIn gsi) async {
    try {
      debugPrint('OAuth: Starting Google Flow...');
      final GoogleSignInAccount? account = await gsi.signIn();
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;
      debugPrint('OAuth: Successfully authorized ${account.email}');
      
      // In a real app, we would exchange this for a long-lived refresh token 
      // on the backend and store it securely per client.
      return auth.accessToken;
    } catch (e) {
      debugPrint('OAuth Error (Google): $e');
      return null;
    }
  }

  static Future<String?> _mockOAuthFlow(String providerName) async {
    debugPrint('OAuth: Starting Mock Flow for $providerName...');
    await Future.delayed(const Duration(seconds: 2));
    return "mock_token_${providerName.toLowerCase().replaceAll(' ', '_')}";
  }
}
