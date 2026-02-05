import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../features/reports/models/source_model.dart';
import 'integration_service.dart';
import '../../features/connectors/models/connected_account_model.dart';
import '../../features/connectors/models/unified_campaign_model.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

class SourcesService {

  /// Pick a file and extract content with Production Grade parsers
  static Future<ReportSource?> pickFileAndProcess(String reportId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'csv', 'md', 'json'],
      withData: true, 
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      final content = await extractTextFromFile(file.bytes!, file.name);

      return ReportSource(
        id: const Uuid().v4(),
        reportId: reportId,
        type: SourceType.file,
        name: file.name,
        uri: file.path ?? 'memory://${file.name}',
        content: content,
        addedAt: DateTime.now(),
      );
    }
    return null;
  }

  /// Extract text from file bytes (PDF, TXT, CSV, etc.)
  static Future<String> extractTextFromFile(List<int> bytes, String fileName) async {
      String content = "";
      try {
        if (fileName.toLowerCase().endsWith('.pdf')) {
          // Robust PDF Extraction
          try {
            final PdfDocument document = PdfDocument(inputBytes: bytes);
            content = PdfTextExtractor(document).extractText();
            document.dispose();
            
            if (content.trim().isEmpty) {
              content = "[PDF Parsed but empty. File might be scanned images only.]";
            }
          } catch (pdfErr) {
            print("PDF Parse Error: $pdfErr");
            content = "Error parsing PDF. Please copy/paste text manually.";
          }
        } else {
          // Text-based fallback (UTF-8)
          try {
            content = utf8.decode(bytes);
          } catch (utfErr) {
            // Try ISO-8859-1 fallback if UTF-8 fails
            content = latin1.decode(bytes); 
          }
        }
      } catch (e) {
        content = "Error reading file format: $e";
      }
      return content;
  }

  /// Add a web source using generic CORS reader or Direct Fetch
  static Future<ReportSource> addWebSource(String reportId, String url) async {
    String content = "Loading...";
    try {
      // PROD STRATEGY: 
      // 1. Try direct fetch (works if target allows CORS)
      // 2. Fallback to a proxy (e.g. corsproxy.io)
      // 3. Last fallback: Request the AI to 'browse' it (simulated via metadata)

      print("Fetching web source: $url");
      final uri = Uri.parse(url);
      
      try {
         // Attempt 1: CorsProxy.io (Production Grade Public Proxy)
         // Note: For sensitive data, a private cloud function proxy is preferred.
         final proxyUrl = "https://corsproxy.io/?${Uri.encodeComponent(url)}";
         final response = await http.get(Uri.parse(proxyUrl));
         
         if (response.statusCode == 200) {
            content = _stripHtml(response.body); // Basic text extraction
            if (content.length > 50000) content = content.substring(0, 50000); // Audit limit
         } else {
            throw Exception('Proxy status ${response.statusCode}');
         }
      } catch (proxyErr) {
         print("Proxy fetch failed: $proxyErr. Trying direct...");
         // Attempt 2: Direct
         final response = await http.get(uri);
         if (response.statusCode == 200) {
            content = _stripHtml(response.body);
         } else {
            content = "Failed to fetch content. Error ${response.statusCode}. (The website might block automated access).";
         }
      }
    } catch (e) {
      content = "Error accessing URL: $e. \nTip: Some sites block readers. Try copying the text manually.";
    }

    return ReportSource(
      id: const Uuid().v4(),
      reportId: reportId,
      type: SourceType.web,
      name: "Web: $url",
      uri: url,
      content: content,
      addedAt: DateTime.now(),
    );
  }

  static String _stripHtml(String html) {
    // Regex-based strip for speed (vs bringing in html package just for this)
    // 1. Remove scripts/styles
    var text = html.replaceAll(RegExp(r'<script\b[^>]*>([\s\S]*?)<\/script>', caseSensitive: false), "");
    text = text.replaceAll(RegExp(r'<style\b[^>]*>([\s\S]*?)<\/style>', caseSensitive: false), "");
    
    // 2. Remove tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), " ");
    
    // 3. Clean whitespace
    text = text.replaceAll(RegExp(r'\s+'), " ").trim();
    
    return text;
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

  /// Fetch real data from a connected account (Ads or Analytics) and add as source
  static Future<ReportSource> fetchAndAddConnectedSource(
      String reportId, 
      ConnectedAccount account, 
      IntegrationService integrationService,
      {DateTime? start, DateTime? end}
  ) async {
      final s = start ?? DateTime.now().subtract(const Duration(days: 30));
      final e = end ?? DateTime.now();
      
      try {
        // Handle based on platform type via IntegrationService
        final data = await integrationService.syncDataForAccount(account, s, e);
        final buffer = StringBuffer();
        
        if (data['type'] == 'ads' && data['campaigns'] != null) {
            // ADS FORMATTING
            final campaigns = (data['campaigns'] as List).map((x) => UnifiedCampaign.fromJson(x)).toList();
            
            buffer.writeln("Campaign Compliance Report (${account.platform.name})");
            buffer.writeln("Period: ${s.toIso8601String()} to ${e.toIso8601String()}");
            buffer.writeln("Campaign,Status,Spend,Impressions,Clicks,CTR,ROAS");
            
            for (var c in campaigns) {
               buffer.writeln("${c.name},${c.status},${c.spend},${c.impressions},${c.clicks},${c.ctr},${c.roas}");
            }
        } 
        else if (data['type'] == 'analytics' && data['report'] != null) {
            // ANALYTICS FORMATTING
            buffer.writeln("Analytics Report (${account.platform.name})");
            buffer.writeln("Period: ${s.toIso8601String()} to ${e.toIso8601String()}");
            
            final report = data['report'] as Map<String, dynamic>;
            final rows = report['rows'] as List?;
            if (rows != null) {
               buffer.writeln("Date,ActiveUsers,ScreenViews,Conversions");
               for (var row in rows) {
                  final dims = row['dimensionValues'] as List;
                  final mets = row['metricValues'] as List;
                  final date = dims.isNotEmpty ? dims[0]['value'] : 'N/A';
                  final users = mets.length > 0 ? mets[0]['value'] : '0';
                  final views = mets.length > 1 ? mets[1]['value'] : '0';
                  final conv = mets.length > 2 ? mets[2]['value'] : '0';
                  buffer.writeln("$date,$users,$views,$conv");
               }
            } else {
               buffer.writeln("No rows returned.");
            }
        }
        else {
           buffer.writeln("Summary Data for ${account.platform.name}");
           if (data['insights'] != null) {
              buffer.writeln("Insights: ${data['insights']}");
           }
        }

        return ReportSource(
          id: const Uuid().v4(),
          reportId: reportId,
          type: data['type'] == 'analytics' ? SourceType.analytics : SourceType.adAccount,
          name: "${account.platform.name}: ${account.accountName}",
          uri: "account://${account.platform.name}/${account.externalAccountId}",
          content: buffer.toString(),
          metadata: {'raw_sync': data},
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
