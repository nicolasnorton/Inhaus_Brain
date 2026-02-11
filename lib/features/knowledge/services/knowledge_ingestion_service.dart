import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../clients/models/client_model.dart';
import '../../clients/models/project_model.dart';
import '../../clients/models/task_model.dart';
import '../../connectors/models/connected_account_model.dart';
import '../models/knowledge_source.dart';
import 'knowledge_api_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class KnowledgeIngestionService {
  final KnowledgeApiService _knowledgeApi;

  KnowledgeIngestionService(this._knowledgeApi);

  Future<void> ingestClient(Client client) async {
    try {
      debugPrint('Autonomous Ingestion: Processing Client ${client.name}...');
      final content = """
Client: ${client.name}
Industry: ${client.industry}
Contact: ${client.primaryContactEmail}
Summary: ${client.description}
Custom Fields: ${client.customFields}
""";
      
      await _knowledgeApi.createDocumentFromText(
        datasetId: 'clients-intelligence', // Assuming a default intelligence dataset
        name: 'Client: ${client.name}',
        text: content,
        chunkSize: _calculateChunkSize(KnowledgeSourceType.text, content),
      );
    } catch (e) {
      debugPrint('⚠️ Autonomous Ingestion Failed for Client ${client.name}: ${_safeError(e)}');
      // Do not rethrow; finding/fixing this shouldn't block user flow
    }
  }

  Future<void> ingestPlatformData(AdPlatform platform, String clientId, String rawData) async {
    final sourceType = platform == AdPlatform.googleAds ? KnowledgeSourceType.googleAds : 
                     platform == AdPlatform.googleAnalytics ? KnowledgeSourceType.ga4 : 
                     KnowledgeSourceType.text;

    debugPrint('Dynamic Ingestion: Processing ${platform.toString().split('.').last} for Client $clientId...');

    // Parse structured data if possible to make it more LLM-friendly
    final formattedText = _formatStructuredData(rawData, sourceType);

    await _knowledgeApi.createDocumentFromText(
      datasetId: 'platform-intelligence-$clientId',
      name: '${platform.name} Sync ${DateTime.now().toIso8601String()}',
      text: formattedText,
      chunkSize: _calculateChunkSize(sourceType, formattedText),
    );
  }

  Future<void> ingestSocialData({
    required String clientId,
    required String platform,
    required String postContent,
    Map<String, dynamic>? metrics,
  }) async {
    debugPrint('Social Ingestion: Processing $platform for Client $clientId...');
    final content = "Platform: $platform\nContent: $postContent\nMetrics: ${jsonEncode(metrics ?? {})}";

    await _knowledgeApi.createDocumentFromText(
      datasetId: 'social-intelligence-$clientId',
      name: '$platform Post ${DateTime.now().millisecondsSinceEpoch}',
      text: content,
      chunkSize: _calculateChunkSize(KnowledgeSourceType.values.firstWhere((e) => e.toString().contains(platform)), content),
    );
  }

  Future<void> ingestPaidMediaData({
    required String clientId,
    required String platform,
    required Map<String, dynamic> performanceData,
  }) async {
    debugPrint('Paid Media Ingestion: Processing $platform for Client $clientId...');
    final content = _formatStructuredData(jsonEncode(performanceData), KnowledgeSourceType.values.firstWhere((e) => e.toString().contains(platform)));

    await _knowledgeApi.createDocumentFromText(
      datasetId: 'paid-media-intelligence-$clientId',
      name: '$platform Performance ${DateTime.now().toIso8601String().split('T')[0]}',
      text: content,
      chunkSize: _calculateChunkSize(KnowledgeSourceType.values.firstWhere((e) => e.toString().contains(platform)), content),
    );
  }

  String _formatStructuredData(String raw, KnowledgeSourceType type) {
    // Basic CSV/JSON heuristic to make data more readable for embedding
    try {
      if (raw.trim().startsWith('{') || raw.trim().startsWith('[')) {
        // Parse and flatten JSON for better RAG retrieval
        try {
          final dynamic parsed = jsonDecode(raw);
          final flattened = _flattenJson(parsed);
          return "Source: ${type.toString().split('.').last}\nData Type: JSON\nContent:\n$flattened";
        } catch (e) {
          debugPrint('JSON decode failed, using raw: $e');
          return "Source: ${type.toString().split('.').last}\nData Type: JSON (Raw)\nContent:\n$raw";
        }
      } else if (raw.contains(',')) {
        // Assume CSV
        final lines = raw.split('\n');
        if (lines.isNotEmpty) {
           final headers = lines.first.split(',');
           final buffer = StringBuffer();
           buffer.writeln("Source: ${type.toString().split('.').last} (CSV Report)");
           for (var i = 1; i < lines.length; i++) {
              final values = lines[i].split(',');
              if (values.length == headers.length) {
                 buffer.writeln("Record ${i}:");
                 for (var j = 0; j < headers.length; j++) {
                    buffer.writeln(" - ${headers[j].trim()}: ${values[j].trim()}");
                 }
                 buffer.writeln("---");
              }
           }
           return buffer.toString();
        }
      }
    } catch (e) {
      debugPrint('Structured parsing failed: $e');
    }
    return raw; // Fallback
  }

  Future<void> ingestProject(Project project, List<ProjectTask> tasks) async {
    debugPrint('Autonomous Ingestion: Processing Project ${project.name}...');
    final taskSummary = tasks.map((t) => "- ${t.title} (${t.status.toString().split('.').last})").join('\n');
    final content = """
Project: ${project.name}
Description: ${project.description}
Status: ${project.status.toString().split('.').last}
Timeline: ${project.startDate} to ${project.endDate}
Tasks:
$taskSummary
""";

    await _knowledgeApi.createDocumentFromText(
      datasetId: 'project-intelligence',
      name: 'Project: ${project.name}',
      text: content,
      chunkSize: _calculateChunkSize(KnowledgeSourceType.text, content),
    );
  }

  Future<void> ingestSource(String datasetId, KnowledgeSource source) async {
    debugPrint('Ingesting Source: ${source.title} into Dataset $datasetId Type: ${source.type.toString().split('.').last}...');
    
    String contentToIngest = source.content;

    // 1. PDF Extraction if we have bytes
    if (source.type == KnowledgeSourceType.pdf && source.bytes != null) {
      try {
        final PdfDocument document = PdfDocument(inputBytes: source.bytes);
        contentToIngest = PdfTextExtractor(document).extractText();
        document.dispose();
      } catch (e) {
        debugPrint("KnowledgeIngestion: PDF extraction failed: $e. Falling back to title.");
      }
    }

    // 2. Index in Knowledge Module
    await _knowledgeApi.createDocumentFromText(
      datasetId: datasetId,
      name: source.title,
      text: contentToIngest,
      chunkSize: _calculateChunkSize(source.type, contentToIngest),
    );
  }

  Future<void> ingestCopilotScreencap(String historySnippet, {List<int>? attachment}) async {
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 2);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        // Create the ingestion future
        final ingestionFuture = _knowledgeApi.createDocumentFromText(
          datasetId: 'agent-learnings',
          name: 'Copilot Learning ${DateTime.now().toIso8601String()}',
          text: historySnippet,
          chunkSize: _calculateChunkSize(KnowledgeSourceType.text, historySnippet),
        );

        // Attempt with timeout (90s total, allowing for retry delays)
        await ingestionFuture.timeout(const Duration(seconds: 90));
        
        // Success - break out of retry loop
        debugPrint('Knowledge ingestion succeeded on attempt ${attempt + 1}');
        return;
      } catch (e) {
        final isLastAttempt = attempt == maxRetries - 1;
        final errorMsg = _safeError(e);
        
        if (isLastAttempt) {
          // Final attempt failed, log and swallow
          debugPrint('Ingestion Failed After $maxRetries Attempts: $errorMsg');
          return;
        }
        
        // Calculate exponential backoff delay
        final delay = initialDelay * (1 << attempt); // 2s, 4s, 8s
        debugPrint('Ingestion Attempt ${attempt + 1} Failed: $errorMsg. Retrying in ${delay.inSeconds}s...');
        
        await Future.delayed(delay);
      }
    }
  }

  static int _calculateChunkSize(KnowledgeSourceType type, String content) {
    // Adaptive Chunking Strategy
    switch (type) {
      case KnowledgeSourceType.googleAds:
      case KnowledgeSourceType.ga4:
      case KnowledgeSourceType.metaAds:
      case KnowledgeSourceType.linkedinAds:
      case KnowledgeSourceType.tiktokAds:
      case KnowledgeSourceType.twitterAds:
        return 300; // Granular chunks for data records
      case KnowledgeSourceType.meta:
      case KnowledgeSourceType.instagram:
      case KnowledgeSourceType.linkedin:
      case KnowledgeSourceType.tiktok:
      case KnowledgeSourceType.twitter:
        return 400; // Specific for social posts
      case KnowledgeSourceType.googleWorkspace:
      case KnowledgeSourceType.gmail:
        return 600; // Medium chunks for emails/docs
      case KnowledgeSourceType.text:
      case KnowledgeSourceType.pdf:
      case KnowledgeSourceType.file:
        return 1000; // Larger chunks for general text
      default:
        return 500; // Default fallback
    }
  }

  static String _safeError(dynamic e) {
    if (e == null) return "Unknown Error (null)";
    try {
      final dynamic err = e;
      return err.toString();
    } catch (_) {
      return "Error parsing exception";
    }
  }

  String _flattenJson(dynamic data, [String prefix = '']) {
    final buffer = StringBuffer();
    
    if (data is Map) {
      data.forEach((key, value) {
        final newKey = prefix.isEmpty ? key : '$prefix.$key';
        if (value is Map || value is List) {
          buffer.write(_flattenJson(value, newKey));
        } else {
          buffer.writeln('$newKey: $value');
        }
      });
    } else if (data is List) {
      for (var i = 0; i < data.length; i++) {
        final newKey = '$prefix[$i]';
        final value = data[i];
        if (value is Map || value is List) {
          buffer.write(_flattenJson(value, newKey));
        } else {
          buffer.writeln('$newKey: $value');
        }
      }
    } else {
      buffer.writeln('$prefix: $data');
    }
    
    return buffer.toString();
  }
}
