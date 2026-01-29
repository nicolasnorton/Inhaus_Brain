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
    // Create the future but don't await it yet
    final ingestionFuture = _knowledgeApi.createDocumentFromText(
      datasetId: 'agent-learnings',
      name: 'Copilot Learning ${DateTime.now().toIso8601String()}',
      text: historySnippet,
      chunkSize: _calculateChunkSize(KnowledgeSourceType.text, historySnippet),
    );

    // We don't need a separate catchError if we handle it in the try-catch block
    // and ensuring the timeout doesn't leave unhandled futures.
    // However, to satisfy the requirement of "silently caught background fails":
    final safeIngestionFuture = ingestionFuture.catchError((e) {
      debugPrint('Background Ingestion Failed (Silently Caught): ${_safeError(e)}');
      throw e; // Rethrow so the try-catch below can catch it
    });

    try {
      // Now await with timeout
      await safeIngestionFuture.timeout(const Duration(seconds: 60));
    } catch (e) {
      // Swallowed to prevent dangling future crashes after timeout
      debugPrint('Ingestion Timeout/Error (Handled): ${_safeError(e)}');
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
