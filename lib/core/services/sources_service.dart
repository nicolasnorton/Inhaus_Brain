import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../features/reports/models/source_model.dart';
import 'integration_service.dart';
import '../../features/connectors/models/connected_account_model.dart';
import '../../features/connectors/models/unified_campaign_model.dart';

class SourcesService {
  
  /// Simulate picking a file and extracting content
  static Future<ReportSource?> pickFileAndProcess(String reportId) async {
    // on web, we need bytes. on mobile, we usually prefer path but to avoid dart:io we use bytes here for simplicity
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'csv', 'md'],
      withData: true, 
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final fileName = file.name;
      
      String content;
      try {
        content = utf8.decode(file.bytes!);
      } catch (e) {
        content = "[Binary/PDF Content Mock] - Extracted text would go here.";
      }

      return ReportSource(
        id: const Uuid().v4(),
        reportId: reportId,
        type: SourceType.file,
        name: fileName,
        uri: file.path ?? 'memory://${file.name}',
        content: content,
        addedAt: DateTime.now(),
      );
    }
    return null;
  }

  /// Add a web source (Mock)
  static Future<ReportSource> addWebSource(String reportId, String url) async {
    // MOCK SCRAPING
    await Future.delayed(const Duration(seconds: 1));
    return ReportSource(
      id: const Uuid().v4(),
      reportId: reportId,
      type: SourceType.web,
      name: "Web: $url",
      uri: url,
      content: "Scraped content from $url...",
      addedAt: DateTime.now(),
    );
  }

  /// Add pasted text source
  static Future<ReportSource> addTextSource(String reportId, String text, String title) async {
    return ReportSource(
      id: const Uuid().v4(),
      reportId: reportId,
      type: SourceType.pastedText,
      name: title.isEmpty ? "Copied Text" : title,
      uri: null,
      content: text,
      addedAt: DateTime.now(),
    );
  }

  /// Add a data connector source (Mock)
  static Future<ReportSource> addConnectorSource(String reportId, String connectorName) async {
     await Future.delayed(const Duration(seconds: 1));
     return ReportSource(
      id: const Uuid().v4(),
      reportId: reportId,
      type: SourceType.dataConnector,
      name: connectorName,
      uri: "connector://$connectorName",
      content: "Data from $connectorName...",
      metadata: {'rows': 500, 'columns': ['date', 'campaign', 'clicks']},
      addedAt: DateTime.now(),
    );
  }

  /// Add an ad account source (Mock)
  static Future<ReportSource> addAccountSource(String reportId, String platformName, String accountId) async {
     await Future.delayed(const Duration(seconds: 1));
     return ReportSource(
      id: const Uuid().v4(),
      reportId: reportId,
      type: SourceType.adAccount,
      name: "$platformName: $accountId",
      uri: "account://$platformName/$accountId",
      content: "Mock ad data for $accountId from $platformName...",
      addedAt: DateTime.now(),
    );
  }

  /// Add an analytics source (Mock)
  static Future<ReportSource> addAnalyticsSource(String reportId, String platformName, String propertyId) async {
     await Future.delayed(const Duration(seconds: 1));
     return ReportSource(
      id: const Uuid().v4(),
      reportId: reportId,
      type: SourceType.analytics,
      name: "$platformName: $propertyId",
      uri: "analytics://$platformName/$propertyId",
      content: "Mock analytics data for $propertyId from $platformName...",
      addedAt: DateTime.now(),
    );
  }

  /// Fetch real data from a connected account and add as source
  static Future<ReportSource> fetchAndAddConnectedSource(
      String reportId, 
      ConnectedAccount account, 
      IntegrationService integrationService,
      {DateTime? start, DateTime? end}
  ) async {
      final s = start ?? DateTime.now().subtract(const Duration(days: 30));
      final e = end ?? DateTime.now();
      
      try {
        final campaigns = await integrationService.getCampaigns(account, s, e);
        
        // Convert campaigns to CSV-like string for the LLM
        final buffer = StringBuffer();
        buffer.writeln("Campaign Compliance Report (${account.platform.name})");
        buffer.writeln("Period: ${s.toIso8601String()} to ${e.toIso8601String()}");
        buffer.writeln("Campaign,Status,Spend,Impressions,Clicks,CTR,ROAS");
        
        for (var c in campaigns) {
           buffer.writeln("${c.name},${c.status},${c.spend},${c.impressions},${c.clicks},${c.ctr},${c.roas}");
        }

        return ReportSource(
          id: const Uuid().v4(),
          reportId: reportId,
          type: SourceType.adAccount,
          name: "${account.platform.name}: ${account.accountName}",
          uri: "account://${account.platform.name}/${account.externalAccountId}",
          content: buffer.toString(),
          metadata: {'campaignCheckCount': campaigns.length},
          addedAt: DateTime.now(),
        );

      } catch (err) {
        // Fallback or error source
        return ReportSource(
          id: const Uuid().v4(),
          reportId: reportId,
          type: SourceType.adAccount,
          name: "Error: ${account.accountName}",
          content: "Failed to fetch data: $err",
          addedAt: DateTime.now(),
        );
      }
  }
}
