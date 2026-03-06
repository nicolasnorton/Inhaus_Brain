import 'package:flutter/foundation.dart';
import 'package:inhaus_brain/core/services/bigquery_service.dart';
import 'package:inhaus_brain/core/services/ai_proxy_service.dart';
import 'package:inhaus_brain/core/tokens/llm_provider.dart';

/// Wraps BigQuery + Gemini-in-BigQuery capabilities.
/// Reuses Firebase/Vertex AI patterns.
class BrainWeaveDataService {
  final BigQueryService _bqService = BigQueryService();

  /// Natural Language to SQL and execution in one go.
  /// Translates a natural language question into BigQuery SQL and runs it.
  Future<List<Map<String, dynamic>>> executeNaturalLanguageQuery(String question) async {
    // 1. Ask Gemini to generate SQL based on Cortex schema
    final schemaContext = '''
    We have a Cortex-compatible BigQuery star schema in `marketing_mart` dataset.
    Tables: dim_campaign, dim_ad_group, dim_ad, fact_daily_ad_performance, fact_conversions, user_client_mapping.
    Fact table columns: report_date, ad_id, campaign_id, client_id, platform, impressions, clicks, spend, conversions, conversion_value, purchase_roas.
    Generate ONLY valid BigQuery Standard SQL to answer this question. NEVER include markdown formatting like ```sql or trailing text.
    Question: $question
    ''';

    try {
      final sqlResponse = await AIProxyService.generateContent(
        prompt: schemaContext,
        config: AIModelConfig(
          provider: AIProvider.gemini,
          modelId: 'gemini-3.1-pro-preview',
          temperature: 0.1,
          maxTokens: 1024,
        ),
      );
      
      final rawSql = sqlResponse['text']?.toString() ?? sqlResponse.toString();
      final cleanSql = rawSql.replaceAll('```sql', '').replaceAll('```', '').trim();

      // 2. Execute against BQ via proxy
      if (cleanSql.isEmpty) {
        throw Exception('Generated SQL is empty.');
      }
      return await _bqService.executeQuery(cleanSql);
    } catch (e) {
      debugPrint('Error in NL to SQL execution: \$e');
      rethrow;
    }
  }

  /// Compare platforms for a given client within a date range
  Future<Map<String, dynamic>> comparePlatforms(String clientId, DateTime start, DateTime end) async {
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    
    final query = '''
      SELECT 
        platform, 
        SUM(impressions) as total_impressions, 
        SUM(clicks) as total_clicks, 
        SUM(spend) as total_spend, 
        SUM(conversions) as total_conversions,
        SAFE_DIVIDE(SUM(conversion_value), NULLIF(SUM(spend), 0)) as roas
      FROM `inhausbrain.marketing_mart.fact_daily_ad_performance`
      WHERE client_id = '\$clientId' 
        AND report_date BETWEEN '\$startStr' AND '\$endStr'
      GROUP BY platform
    ''';

    final rows = await _bqService.executeQuery(query);
    return {'startDate': startStr, 'endDate': endStr, 'platformData': rows};
  }
}
