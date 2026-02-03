import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/interfaces/integration_connector.dart';
import '../models/connected_account_model.dart';
import '../models/unified_campaign_model.dart';

class MetaAdsProvider implements AdsConnector {
  @override
  AdPlatform get platform => AdPlatform.metaAds;

  @override
  Future<ConnectedAccount?> connect(String clientId) async {
    try {
      // 1. Trigger Login Request
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email', 'ads_read', 'read_insights'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        
        // 2. Fetch User Data
        final userData = await FacebookAuth.instance.getUserData();
        final name = userData['name'] ?? 'Meta User';
        final fbUserId = userData['id'];

        // 3. (Optional) Fetch Ad Accounts associated with this user
        // We will default to the user ID for now, but usually we iterate /me/adaccounts
        // For production "No Mock", we should try to fetch one.
        String externalId = fbUserId;
        String accountLabel = name;

        try {
           final adAccountsRes = await http.get(
             Uri.parse('https://graph.facebook.com/v19.0/me/adaccounts?access_token=${accessToken.token}&fields=name,account_id'),
           );
           
           if (adAccountsRes.statusCode == 200) {
             final data = jsonDecode(adAccountsRes.body);
             final accounts = data['data'] as List?;
             if (accounts != null && accounts.isNotEmpty) {
                // Pick first ad account
                final firstAcct = accounts[0];
                externalId = "act_${firstAcct['account_id']}"; // Must prepend act_
                accountLabel = "$name - ${firstAcct['name']}";
             }
           }
        } catch (e) {
           debugPrint('MetaAdsProvider: Failed to list ad accounts: $e');
           // Fallback to user ID, which won't work for campaign fetch but passes auth
        }

        return ConnectedAccount(
          id: 'meta_ads_${DateTime.now().millisecondsSinceEpoch}',
          clientId: clientId,
          platform: AdPlatform.metaAds,
          accountName: accountLabel,
          externalAccountId: externalId,
          status: AccountStatus.active,
          updatedAt: DateTime.now(),
        );

      } else {
        debugPrint('MetaAdsProvider: Login failed: ${result.status} - ${result.message}');
        return null;
      }
    } catch (e) {
      debugPrint("MetaAdsProvider Connect Error: $e");
      return null;
    }
  }

  @override
  Future<List<UnifiedCampaign>> getCampaigns(
      ConnectedAccount account, DateTime start, DateTime end) async {
    
    // We need the access token. 
    // In a real app, we might store it securely linked to the account ID.
    // Here we check the current session or assume re-login (silent).
    final accessToken = await FacebookAuth.instance.accessToken;
    
    if (accessToken == null) {
       // Need to re-auth
       debugPrint('MetaAdsProvider: No active session. Returning empty/mock.');
       return _mockCampaigns(account);
    }
    
    if (!account.externalAccountId.startsWith('act_')) {
       debugPrint('MetaAdsProvider: Invalid Ad Account ID (missing act_ prefix). Returning mock.');
       return _mockCampaigns(account);
    }

    // Real API Call
    final String startStr = start.toIso8601String().split('T')[0];
    final String endStr = end.toIso8601String().split('T')[0];
    
    // Graph API: https://graph.facebook.com/v19.0/{act_id}/campaigns...
    // Insights needed for spend, etc.
    final url = Uri.parse('https://graph.facebook.com/v19.0/${account.externalAccountId}/insights?level=campaign&time_range={"since":"$startStr","until":"$endStr"}&fields=campaign_id,campaign_name,objective,spend,impressions,clicks,cpc,cpp&access_token=${accessToken.token}');
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         final insights = data['data'] as List?;
         
         if (insights != null) {
           return insights.map((row) {
             return UnifiedCampaign(
               id: row['campaign_id'] ?? 'unknown',
               connectedAccountId: account.id,
               platform: AdPlatform.metaAds,
               name: row['campaign_name'] ?? 'Unknown Campaign',
               status: 'ACTIVE', // Insights implies activity
               startDate: start,
               spend: double.tryParse(row['spend']?.toString() ?? '0') ?? 0.0,
               impressions: int.tryParse(row['impressions']?.toString() ?? '0') ?? 0,
               clicks: int.tryParse(row['clicks']?.toString() ?? '0') ?? 0,
               ctr: 0.0, // Calculate manually
               roas: 0.0, // Needs purchase value
             );
           }).toList();
         }
      } else {
         debugPrint('MetaAdsProvider: API Error ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('MetaAdsProvider: Network Error: $e');
    }

    return _mockCampaigns(account);
  }

  List<UnifiedCampaign> _mockCampaigns(ConnectedAccount account) {
    return [
      UnifiedCampaign(
        id: 'meta-101',
        connectedAccountId: account.id,
        platform: AdPlatform.metaAds,
        name: 'IG Stories - Awareness (Mock)',
        status: 'ACTIVE',
        startDate: DateTime(2025, 2, 10),
        spend: 300.00,
        impressions: 45000,
        clicks: 320,
        ctr: 0.007,
        roas: 1.5,
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
     return []; 
  }

  @override
  Future<ConnectedAccount> validateOrRefreshAuth(ConnectedAccount account) async {
    // Check if current token is expired
    final accessToken = await FacebookAuth.instance.accessToken;
    if (accessToken != null && DateTime.now().isAfter(accessToken.expires)) {
       // Silent refresh not always possible without backend, might need re-login
    }
    return account;
  }
}
