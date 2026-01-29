import 'package:flutter/foundation.dart';
import '../../clients/models/client_model.dart';
import '../../clients/models/project_model.dart';
import '../../clients/models/task_model.dart';
import '../../connectors/models/connected_account_model.dart';
import '../models/knowledge_source.dart';
import 'knowledge_api_service.dart';

class KnowledgeIngestionService {
  final KnowledgeApiService _knowledgeApi;

  KnowledgeIngestionService(this._knowledgeApi);

  Future<void> ingestClient(Client client) async {
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
  }

  Future<void> ingestPlatformData(AdPlatform platform, String clientId, String rawData) async {
    debugPrint('Dynamic Ingestion: Processing ${platform.name} for Client $clientId...');
    
    final sourceType = platform == AdPlatform.googleAds ? KnowledgeSourceType.googleAds : 
                     platform == AdPlatform.googleAnalytics ? KnowledgeSourceType.ga4 : 
                     KnowledgeSourceType.text;

    await _knowledgeApi.createDocumentFromText(
      datasetId: 'platform-intelligence-$clientId',
      name: '${platform.name} Sync ${DateTime.now().toIso8601String()}',
      text: rawData,
      chunkSize: _calculateChunkSize(sourceType, rawData),
    );
  }

  Future<void> ingestProject(Project project, List<ProjectTask> tasks) async {
    debugPrint('Autonomous Ingestion: Processing Project ${project.name}...');
    final taskSummary = tasks.map((t) => "- ${t.title} (${t.status.name})").join('\n');
    final content = """
Project: ${project.name}
Description: ${project.description}
Status: ${project.status.name}
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
        return 300; // Granular chunks for data records
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
}
