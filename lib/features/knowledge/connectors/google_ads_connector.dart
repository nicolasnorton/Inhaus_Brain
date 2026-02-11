import 'package:flutter/foundation.dart';
import '../../../core/auth/secret_vault_service.dart';
import '../models/knowledge_source.dart';
import 'knowledge_connector.dart';

/// Connector for Google Ads Reporting API.
class GoogleAdsConnector implements KnowledgeConnector {
  final SecretVaultService _vault;
  String? _accessToken;

  GoogleAdsConnector(this._vault);

  @override
  String get connectorId => 'google_ads';

  @override
  String get name => 'Google Ads';

  @override
  Future<void> authenticate() async {
    _accessToken = await _vault.getSecret('google_ads_access_token');
    if (_accessToken == null) {
      throw Exception('Google Ads access token not found.');
    }
  }

  @override
  Future<List<KnowledgeConnectorDocument>> fetchRecentUpdates({DateTime? since}) async {
    if (_accessToken == null) await authenticate();

    try {
      debugPrint('GoogleAdsConnector: Fetching campaign performance summary...');
      await Future.delayed(const Duration(milliseconds: 1200));

      return [
        KnowledgeConnectorDocument(
          externalId: 'campaign_pmax_001',
          title: 'Google Ads: Performance Max Campaign',
          content: 'Daily Performance Summary: Total Spend 500, Conv 12. ROAS 4.5. Top performing creative: "Spring Sale Video".',
          type: KnowledgeSourceType.googleAds,
          publishedAt: DateTime.now(),
          metadata: {
            'campaign_id': '789456',
            'spend': 500.0,
            'conversions': 12,
            'roas': 4.5,
          },
        ),
      ];
    } catch (e) {
      debugPrint('GoogleAdsConnector Error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> fetchMetrics(String externalId) async {
    return {
      'impressions': 45000,
      'clicks': 1200,
      'ctr': 2.67,
      'cost_per_click': 0.42,
    };
  }
}
